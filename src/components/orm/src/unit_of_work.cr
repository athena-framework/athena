# Tracks the entities an `AORM::EntityManager` manages, and writes their changes to the database when it is flushed.
#
# The unit of work keeps an identity map of every managed entity, keyed by class and identifier, so loading the same row more than once returns the same instance.
# It also keeps a copy of each managed entity's data as of when it was loaded or last flushed.
# On `AORM::EntityManager#flush`, it compares each managed entity against that copy to compute its change set.
# It then issues the INSERT, UPDATE and DELETE statements for new, changed and removed entities within a single transaction, ordered so that rows are inserted before the rows referencing them.
#
# Each entity manager owns one unit of work, available via `AORM::EntityManager#unit_of_work`.
# It is usually only used indirectly through the entity manager, whose `#persist`, `#remove` and `#flush` methods delegate to it.
#
# ## Inspecting a Flush
#
# The read side of the unit of work is mostly useful within flush event listeners, to see what a flush is about to write.
# For example, a listener on `AORM::Events::OnFlushEventArgs` runs after every change set has been computed, but before any SQL is executed:
#
# ```
# dispatcher = AED::EventDispatcher.new
#
# dispatcher.listener AORM::Events::OnFlushEventArgs do |event|
#   uow = event.entity_manager.unit_of_work
#
#   uow.scheduled_entity_insertions.each do |entity|
#     Log.info { "Inserting #{entity.class}" }
#   end
#
#   uow.scheduled_entity_updates.each do |entity|
#     uow.entity_changeset(entity).each do |field, change|
#       Log.info { "#{entity.class}##{field}: #{change.old.try &.value} -> #{change.new.value}" }
#     end
#   end
#
#   uow.scheduled_entity_deletions.each do |entity|
#     Log.info { "Deleting #{entity.class}" }
#   end
# end
#
# em = AORM::EntityManager.new connection, dispatcher
# ```
#
# Inserts and updates are written from the change sets computed before `AORM::Events::OnFlushEventArgs` is dispatched.
# A listener of that event that persists an entity computes its change set with `#compute_change_set`, and one that changes a managed entity recomputes it with `#recompute_single_entity_change_set`.
#
# WARNING: Directly calling methods on the unit of work that change its state is not supported.
# Use the `AORM::EntityManager` API instead.
class Athena::ORM::UnitOfWork
  # A field's change within a change set, as returned by `UnitOfWork#entity_changeset`.
  #
  # `#old` is the value the field had when the entity was loaded or last flushed, and is `nil` for entities being inserted.
  # `#new` is the value that is being written.
  # Read the underlying values with `#value`; enum fields hold the integer they're stored as.
  record Change, old : AORM::Mapping::Value?, new : AORM::Mapping::Value

  # The state of an entity in relation to a `UnitOfWork`, as returned by `UnitOfWork#entity_state`.
  enum EntityState
    # The entity has a persistent identity and is managed by the unit of work, so its changes are written on flush.
    # This includes new entities that have been persisted but not yet flushed.
    Managed

    # The entity has no persistent identity and isn't associated with the unit of work, such as one just created with `.new`.
    New

    # The entity has a persistent identity, but isn't (or is no longer) associated with the unit of work, such as after `AORM::EntityManager#clear` or `AORM::EntityManager#detach`.
    Detached

    # The entity is managed by the unit of work, but is scheduled to be deleted from the database on the next flush.
    Removed
  end

  # :nodoc:
  private class InsertBatch
    getter class_metadata : Mapping::ClassInterface
    getter entities : Array(AORM::Entity)

    def initialize(@class_metadata : Mapping::ClassInterface, @entities : Array(AORM::Entity)); end

    def self.batch_by_entity_type(em : AORM::EntityManagerInterface, entities : Array(AORM::Entity)) : Array(self)
      current_metadata = nil
      batches = [] of InsertBatch
      batch_index = -1

      entities.each do |entity|
        entity_metadata = em.class_metadata entity.class

        # Metadata is cached per entity class, so identity stands in for comparing the classes; comparing two arbitrary entity classes with `!=` compiles to a branch for every pair of entity classes.
        if !current_metadata.same?(entity_metadata) || (!entity_metadata.id_generator.is_a?(ID::AssignedGenerator))
          current_metadata = entity_metadata
          batches << new(entity_metadata, [entity])
          batch_index += 1

          next
        end

        batches[batch_index].entities << entity
      end

      batches
    end
  end

  # :nodoc:
  def self.id_hash_by_identifier(identifier : Hash(String | Number, _)) : String
    String.build do |io|
      first = true
      identifier.each_value do |v|
        io << ' ' unless first
        first = false

        raw = v.is_a?(AORM::Mapping::Value) ? v.value : v

        case raw
        when ::Bool then io << (raw ? "1" : "")
        else             io << raw
        end
      end
    end
  end

  @identity_map = Hash(AORM::Entity.class, Hash(String, AORM::Entity)).new.compare_by_identity

  # Stores the value of each of an entity's PK
  @entity_identifiers = Hash(AORM::Entity, Hash(String, AORM::Mapping::Value)).new.compare_by_identity

  @entity_states = Hash(AORM::Entity, EntityState).new.compare_by_identity

  # Pending entity deletions
  @entity_deletions = Set(AORM::Entity).new.compare_by_identity

  # Pending entity insertions
  @entity_insertions = Set(AORM::Entity).new.compare_by_identity

  # Pending entity updates
  @entity_updates = Set(AORM::Entity).new.compare_by_identity

  @entity_persisters = Hash(AORM::Entity.class, AORM::Persisters::Entity::Interface).new.compare_by_identity
  @collection_persisters = Hash(String, Athena::ORM::Persisters::Collection::Interface).new

  @original_entity_data = Hash(AORM::Entity, Hash(String, Mapping::Value)).new do |hash, key|
    hash[key] = Hash(String, Mapping::Value).new
  end.compare_by_identity
  @entity_change_sets = Hash(AORM::Entity, Hash(String, Change)).new.compare_by_identity
  @orphan_removals = Set(AORM::Entity).new.compare_by_identity

  @non_cascaded_new_detected_entities = Hash(AORM::Entity, Tuple(AORM::Mapping::Association, AORM::Entity)).new.compare_by_identity

  # Collections scheduled for deletion (cleared or owner removed)
  @collection_deletions = Set(AORM::BasePersistentCollection).new.compare_by_identity

  # Collections scheduled for update (elements added or removed)
  @collection_updates = Set(AORM::BasePersistentCollection).new.compare_by_identity

  # Collections that have been visited during changeset computation
  @visited_collections = Set(AORM::BasePersistentCollection).new.compare_by_identity

  # Per-collection list of entities flagged for removal during change-set computation; applied after the transaction commits, alongside snapshots.
  @pending_collection_element_removals = Hash(AORM::BasePersistentCollection, Array(AORM::Entity)).new.compare_by_identity

  # Per-entity changeset patches that must be applied as follow-up UPDATEs
  # after the main inserts run — needed when a FK can't be set during INSERT
  # because the referenced row hasn't been written yet (i.e. cyclic FKs).
  @extra_updates = Hash(AORM::Entity, Hash(String, Change)).new.compare_by_identity

  # ToOne associations whose target wasn't in the identity map at hydration time.
  # Resolved (eager-loaded) by the hydrator's `cleanup` after the main cursor closes — issuing a SELECT during hydration would conflict with the active result set on the same connection.
  # `target_id` nil means inverse side (load_one_to_one_entity); non-nil means owning side (find by FK).
  private record PendingToOneResolution,
    source : AORM::Entity,
    field_name : String,
    target_class : AORM::Entity.class,
    target_id : Hash(String, DB::Any)?

  @pending_to_one_resolutions = [] of PendingToOneResolution
  @listeners_invoker : AORM::ListenersInvoker
  @event_dispatcher : ACTR::EventDispatcher::Interface?

  # :nodoc:
  getter identifier_flattener : AORM::Utility::IdentifierFlattener { AORM::Utility::IdentifierFlattener.new(self, @em.metadata_factory) }

  # :nodoc:
  def initialize(
    @em : AORM::EntityManagerInterface,
  )
    @event_dispatcher = @em.event_dispatcher
    @listeners_invoker = AORM::ListenersInvoker.new @em
  end

  # :nodoc:
  def commit : Nil
    # TODO: Ensure connected to primary

    self.dispatch_pre_flush_event

    self.compute_changesets

    # Nothing to do
    if @entity_deletions.empty? && @entity_insertions.empty? && @entity_updates.empty? && @orphan_removals.empty? && @collection_deletions.empty? && @collection_updates.empty?
      self.dispatch_on_flush_event
      self.dispatch_post_flush_event

      self.post_commit_cleanup

      return
    end

    # TODO: Handle associations
    self.assert_that_there_are_no_unintentionally_non_persisted_associations

    @orphan_removals.each do |orphan|
      self.remove orphan
    end

    self.dispatch_on_flush_event

    connection = @em.connection
    connection.begin_transaction

    successful = false

    begin
      # Collection deletions (deletions of complete collections)
      @collection_deletions.each do |collection|
        # Deferred explicit tracked collections can be removed only when owning relation was persisted
        owner = collection.owner

        # TODO: Handle change tracking and dirty checks
      end

      unless @entity_insertions.empty?
        # Perform entity insertions first, so that all new entities have their rows in the database
        # and can be referred to by foreign keys. The commit order only needs to take new entities
        # into account (new entities referring to other new entities), since all other types (entities
        # with updates or scheduled deletions) are currently not a problem, since they are already
        # in the database.
        self.execute_inserts
      end

      unless @entity_updates.empty?
        self.execute_updates
      end

      unless @extra_updates.empty?
        self.execute_extra_updates
      end

      # Handle collection updates after entity inserts
      @collection_updates.each do |collection|
        self.collection_persister(collection.association).update collection
      end

      unless @entity_deletions.empty?
        self.execute_deletions
      end

      connection.commit

      successful = true
    ensure
      unless successful
        @em.close

        connection.rollback if connection.transaction_active?

        self.after_transaction_rolled_back
      end
    end

    self.after_transaction_complete

    # Apply pending element removals, then snapshot
    @visited_collections.each do |collection|
      if pending = @pending_collection_element_removals[collection]?
        pending.each { |entity| collection.remove_element entity }
      end

      collection.take_snapshot
    end

    self.dispatch_post_flush_event

    self.post_commit_cleanup
  end

  private def dispatch_pre_flush_event : Nil
    @event_dispatcher.try &.dispatch AORM::Events::PreFlushEventArgs.new @em
  end

  private def dispatch_on_flush_event : Nil
    @event_dispatcher.try &.dispatch AORM::Events::OnFlushEventArgs.new @em
  end

  private def dispatch_post_flush_event : Nil
    @event_dispatcher.try &.dispatch AORM::Events::PostFlushEventArgs.new @em
  end

  private def after_transaction_rolled_back : Nil
    # TODO: CachedPersisters?
  end

  private def after_transaction_complete : Nil
    # TODO: CachedPersisters?
  end

  # Returns the entities that will be inserted on the next flush.
  #
  # Entities are scheduled for insertion when they are persisted.
  def scheduled_entity_insertions : Set(AORM::Entity)
    @entity_insertions
  end

  # Returns the entities that will be deleted on the next flush.
  #
  # Entities are scheduled for deletion when they are removed.
  def scheduled_entity_deletions : Set(AORM::Entity)
    @entity_deletions
  end

  # Returns the managed entities that changed, and will be updated by the current flush.
  #
  # Updates are only known once a flush has computed the change sets, so this is empty outside of a flush.
  def scheduled_entity_updates : Set(AORM::Entity)
    @entity_updates
  end

  # :nodoc:
  def assign_post_insert_id(entity : AORM::Entity, id_hash : Hash(String, Mapping::Value)) : Nil
    class_metadata = @em.class_metadata entity.class
    typed_id_hash = Hash(String, Mapping::Value).new

    id_hash.each do |id_field, value_wrapper|
      typed_value = self.convert_field_identifier_to_crystal_value class_metadata, id_field, value_wrapper.value
      class_metadata.assign_identifier entity, id_field, typed_value
      typed_id_hash[id_field] = class_metadata.create_column_value(id_field, typed_value).as Mapping::Value
      @original_entity_data[entity][id_field] = typed_id_hash[id_field]
    end

    @entity_identifiers[entity] = typed_id_hash
    @entity_states[entity] = :managed

    self.add_to_identity_map entity
  end

  private def convert_field_identifier_to_crystal_value(class_metadata : Mapping::ClassInterface, field_name : String, value : _)
    @em.connection.convert_to_crystal_value value, class_metadata.type_of_field(field_name)
  end

  private def assert_that_there_are_no_unintentionally_non_persisted_associations : Nil
    # Find entities that were detected as NEW through non-cascading associations
    # but were never scheduled for insertion (either explicitly or via cascade)
    entities_needing_cascade_persist = @non_cascaded_new_detected_entities.reject do |entity, _|
      @entity_insertions.includes?(entity)
    end

    @non_cascaded_new_detected_entities.clear

    return if entities_needing_cascade_persist.empty?

    raise "new entities found through relationships"
  end

  private def post_commit_cleanup : Nil
    @entity_insertions.clear
    @entity_updates.clear
    @entity_deletions.clear
    @entity_change_sets.clear
    @extra_updates.clear
    @orphan_removals.clear
    @collection_deletions.clear
    @collection_updates.clear
    @visited_collections.clear
    @pending_collection_element_removals.clear
  end

  private def execute_inserts : Nil
    batched_by_type = InsertBatch.batch_by_entity_type @em, self.compute_insert_execution_order
    events_to_dispatch = Array({AORM::Mapping::ClassInterface, AORM::Entity}).new

    batched_by_type.each do |batch|
      cm = batch.class_metadata

      persister = self.entity_persister cm.entity_class

      batch.entities.each do |entity|
        persister.add_insert entity
        @entity_insertions.delete entity
      end

      persister.execute_inserts

      batch.entities.each do |entity|
        unless @entity_identifiers.has_key? entity
          self.add_to_entity_identifier_and_entity_map cm, entity
        end

        events_to_dispatch << {cm, entity}
      end
    end

    events_to_dispatch.each do |(m, e)|
      @listeners_invoker.invoke m, e, m.create_post_persist_event e, @em
    end
  end

  protected def compute_insert_execution_order : Array(AORM::Entity)
    sort = Internal::TopologicalSort.new

    @entity_insertions.each do |entity|
      sort.add_node entity
    end

    @entity_insertions.each do |entity|
      class_metadata = @em.class_metadata entity.class

      class_metadata.association_mappings.each_value do |assoc|
        # ManyToMany owning sides write to a join table after the row inserts,
        # so they don't constrain insertion order.
        next unless assoc.is_a?(Mapping::ToOneOwningSide)

        target = class_metadata.field_value(entity, assoc.field_name)
        next if target.nil?
        next unless target.is_a?(AORM::Entity)
        # Only enforce ordering when the target is also being inserted in this flush.
        next unless sort.has_node? target

        # If the FK is nullable we can break the cycle by writing NULL first and
        # patching it up via an extra update; if not, the edge is mandatory.
        join_column = assoc.join_columns.first?
        is_nullable = join_column.nil? || join_column.nullable.nil? || join_column.nullable == true

        sort.add_edge entity, target, is_nullable
      end
    end

    sort.sort
  end

  private def add_to_entity_identifier_and_entity_map(class_metadata : Mapping::ClassInterface, entity : AORM::Entity) : Nil
    identifier = Hash(String, AORM::Mapping::Value).new

    class_metadata.identifier.each do |id_field|
      orig_value = class_metadata.get_field_value entity, id_field

      value = nil
      if class_metadata.association_mappings.has_key?(id_field) && orig_value.is_a?(AORM::Entity)
        value = self.single_identifier_value orig_value
      end

      identifier[id_field] = Mapping::ColumnValue.new id_field, value || orig_value
      @original_entity_data[entity][id_field] = Mapping::ColumnValue.new id_field, orig_value
    end

    @entity_states[entity] = :managed
    @entity_identifiers[entity] = identifier

    self.add_to_identity_map entity
  end

  private def execute_updates : Nil
    self.compute_update_execution_order.each do |entity|
      class_metadata = @em.class_metadata entity.class
      persister = self.entity_persister class_metadata.entity_class

      @listeners_invoker.invoke class_metadata, entity, class_metadata.create_pre_update_event entity, @em

      self.recompute_single_entity_change_set class_metadata, entity

      unless @entity_change_sets[entity]?.try &.empty?
        persister.update entity
      end

      @entity_updates.delete entity

      @listeners_invoker.invoke class_metadata, entity, class_metadata.create_post_update_event entity, @em
    end
  end

  private def execute_deletions : Nil
    entities = self.compute_delete_execution_order
    events_to_dispatch = Array({AORM::Mapping::ClassInterface, AORM::Entity}).new

    entities.each do |entity|
      self.remove_from_identity_map entity

      class_metadata = @em.class_metadata entity.class
      persister = self.entity_persister class_metadata.entity_class

      persister.delete entity

      @entity_deletions.delete entity
      @entity_identifiers.delete entity
      @original_entity_data.delete entity
      @entity_states.delete entity

      # This entity after deletion treated as NEW, even if the obtained by a new entity because the old one went out of scope.
      # @entityStates[entity] = :new
      unless class_metadata.identifier_natural?
        class_metadata.set_field_value entity, class_metadata.identifier.first, nil
      end

      events_to_dispatch << {class_metadata, entity}
    end

    events_to_dispatch.each do |(m, e)|
      @listeners_invoker.invoke m, e, m.create_post_remove_event e, @em
    end
  end

  # Orders updates by class name, then by identifier hash, so concurrent flushes touching the same rows acquire row locks in the same order and cannot deadlock each other.
  # Identifier hashes compare as strings, so numeric ids sort lexically; only a consistent order matters here.
  private def compute_update_execution_order : Array(AORM::Entity)
    @entity_updates.to_a.sort_by! { |entity| {entity.class.name, self.id_hash_of_entity(entity)} }
  end

  private def compute_delete_execution_order : Array(AORM::Entity)
    strongly_connected_components = Internal::StronglyConnectedComponents.new
    sort = Internal::TopologicalSort.new

    @entity_deletions.each do |entity|
      strongly_connected_components.add_node entity
      sort.add_node entity
    end

    # First, consider only "on delete cascade" associations between entities
    # and find strongly connected groups. Once we delete any one of the entities
    # in such a group, _all_ of the other entities will be removed as well. So,
    # we need to treat those groups like a single entity when performing delete
    # order topological sorting.
    @entity_deletions.each do |entity|
      class_metadata = @em.class_metadata entity.class

      # TODO: Handle associations
    end

    strongly_connected_components.find_strongly_connected_components

    # Now do the actual topological sorting to find the delete order.
    @entity_deletions.each do |entity|
      class_metadata = @em.class_metadata entity.class

      # Get the entities representing the SCC
      entity_component = strongly_connected_components.node_representing_strongly_connected_component entity

      # When $entity is part of a non-trivial strongly connected component group
      # (a group containing not only those entities alone), make sure we process it _after_ the
      # entity representing the group.
      # The dependency direction implies that "$entity depends on $entityComponent
      # being deleted first". The topological sort will output the depended-upon nodes first.
      if entity_component != entity
        sort.add_edge entity, entity_component, false
      end

      # TODO: Handle associations
    end

    sort.sort
  end

  # :nodoc:
  def persist(entity : AORM::Entity) : Nil
    visited = Set(AORM::Entity).new

    self.persist entity, visited
  end

  private def persist(entity : AORM::Entity, visited : Set(AORM::Entity)) : Nil
    # Unwrap loaded proxies to their inner entity; skip unloaded proxies (their target is already in DB, nothing to persist).
    if entity.is_a?(AORM::Proxy)
      return unless inner = entity.inner?
      return self.persist inner, visited
    end

    return unless visited.add? entity

    class_metadata = @em.class_metadata entity.class

    # We assume NEW, so DETACHED entities result in an exception on flush (constraint violation).
    # If we would detect DETACHED here we would throw an exception anyway with the same
    # consequences (not recoverable/programming error), so just assuming NEW here
    # lets us avoid some database lookups for entities with natural identifiers.
    case self.entity_state(entity, :new)
    in .managed? then return # TODO: Handle change tracking
    in .new?     then self.persist_new class_metadata, entity
    in .removed? # Remanage the entity
      @entity_deletions.delete entity
      self.add_to_identity_map entity

      # TODO: Handle change tracking

      @entity_states[entity] = :managed
    in .detached? then raise "Detached entity #{entity.class} cannot be persisted"
    end

    self.cascade_persist entity, visited
  end

  # :nodoc:
  def remove(entity : AORM::Entity) : Nil
    visited = Set(AORM::Entity).new

    self.remove entity, visited
  end

  private def remove(entity : AORM::Entity, visited : Set(AORM::Entity)) : Nil
    # Remove a proxy's target instead, loading it first if needed, since its lifecycle callbacks and cascades need the entity itself.
    entity = entity.inner.as(AORM::Entity) if entity.is_a?(AORM::Proxy)

    return unless visited.add? entity

    # Cascade first, because schedule_for_delete() removes the entity from the identity map, which
    # can cause problems when a lazy proxy has to be initialized for the cascade operation.
    self.cascade_remove entity, visited

    class_metadata = @em.class_metadata entity.class

    case self.entity_state entity
    in .new?, .removed? then return # noop
    in .managed?
      @listeners_invoker.invoke class_metadata, entity, class_metadata.create_pre_remove_event entity.as(AORM::Entity), @em

      self.schedule_for_delete entity
    in .detached? then raise "Detached entity #{entity.class} cannot be removed" # TODO: Make this an actual exception
    end
  end

  # :nodoc:
  #
  # Re-loads *entity* from the database and applies the fresh row to its in-memory state, discarding any pending changes.
  # The entity must be in the MANAGED state.
  def refresh(entity : AORM::Entity, lock_mode : AORM::LockMode? = nil) : Nil
    # TODO: Handle pessimistic locking
    state = self.entity_state entity
    raise "Cannot refresh entity that is not managed" unless state.managed?

    class_metadata = @em.class_metadata entity.class
    id = self.entity_identifier(entity).transform_values &.value

    # The persister routes through `create_entity`; the refresh hint signals
    # that an existing identity-map entry should be updated rather than
    # short-circuited.
    hints = AORM::Query::Hints.new refresh: true
    self.entity_persister(entity.class).load id, entity, nil, hints
  end

  # :nodoc:
  #
  # Schedules a collection for deletion (all rows in join table).
  def schedule_collection_deletion(collection : AORM::PersistentCollection(AORM::Entity)) : Nil
    @collection_deletions << collection
  end

  # :nodoc:
  #
  # Schedules a collection for update (insert/delete diff).
  def schedule_collection_update(collection : AORM::PersistentCollection(AORM::Entity)) : Nil
    @collection_updates << collection
  end

  # :nodoc:
  #
  # Detaches *entity* from the UnitOfWork: drops it from the identity map and clears every state-tracking ivar that referenced it.
  # The entity itself is not modified — callers that hold the reference can keep using it; it just no longer participates in flush.
  # Cascades through associations whose mapping has `cascade: ["detach"]`.
  def detach(entity : AORM::Entity) : Nil
    visited = Set(AORM::Entity).new

    self.do_detach entity, visited
  end

  private def do_detach(entity : AORM::Entity, visited : Set(AORM::Entity), no_cascade : Bool = false) : Nil
    if entity.is_a?(AORM::Proxy)
      if inner = entity.inner?
        # Detach a loaded proxy's target instead.
        entity = inner.as(AORM::Entity)
      else
        # An unloaded proxy is detached as is, without loading it, since none of its target's associations were loaded through it.
        no_cascade = true
      end
    end

    return unless visited.add? entity

    case self.entity_state(entity, :detached)
    in .managed?
      self.remove_from_identity_map(entity) if self.is_in_identity_map(entity)

      @entity_insertions.delete entity
      @entity_updates.delete entity
      @entity_deletions.delete entity
      @entity_identifiers.delete entity
      @entity_states.delete entity
      @original_entity_data.delete entity
    in .new?, .detached?
      return
    in .removed?
      # `removed` already implies the entity is on its way out; treat as no-op.
      return
    end

    self.cascade_detach(entity, visited) unless no_cascade
  end

  private def cascade_detach(entity : AORM::Entity, visited : Set(AORM::Entity)) : Nil
    class_metadata = @em.class_metadata entity.class

    association_mappings = class_metadata.association_mappings.select { |_, v| v.cascade_detach? }

    association_mappings.each_value do |assoc|
      related_entities = class_metadata.get_field_value entity, assoc.field_name

      case related_entities
      when AORM::BasePersistentCollection
        related_entities.unwrap.each { |related_entity| self.do_detach related_entity.as(AORM::Entity), visited if related_entity.is_a?(AORM::Entity) }
      when AORM::BaseCollection, Enumerable(AORM::Entity)
        related_entities.each { |related_entity| self.do_detach related_entity.as(AORM::Entity), visited if related_entity.is_a?(AORM::Entity) }
      when AORM::Entity
        self.do_detach related_entities, visited
      end
    end
  end

  # Removes a removed entity from all collections it belongs to.
  # Iterates through all managed entities to find collections containing the removed entity.
  private def cascade_remove(entity : AORM::Entity, visited : Set(AORM::Entity)) : Nil
    class_metadata = @em.class_metadata entity.class

    association_mappings = class_metadata.association_mappings.select { |_, v| v.cascade_remove? }

    unless association_mappings.empty?
      self.initialize_object entity
    end

    entities_to_cascade = [] of AORM::Entity

    association_mappings.each_value do |assoc|
      related_entities = class_metadata.get_field_value entity, assoc.field_name

      case related_entities
      when AORM::BaseCollection, Enumerable(AORM::Entity)
        related_entities.each do |related_entity|
          entities_to_cascade << related_entity if related_entity.is_a?(AORM::Entity)
        end
      when AORM::Entity
        entities_to_cascade << related_entities
      end
    end

    entities_to_cascade.each do |related_entity|
      self.remove related_entity, visited
    end
  end

  # :nodoc:
  def initialize_object(entity : AORM::Entity) : Nil
    # TODO: initialize `Ghost` type?
  end

  protected def collection_persister(assoc : Mapping::Association)
    role = assoc.type

    if persister = @collection_persisters[role]?
      return persister
    end

    persister = case role
                when "many_to_many" then AORM::Persisters::Collection::ManyToManyPersister.new @em
                else
                  raise "Unsupported collection persister role #{role}."
                end

    # TODO: Handle caching?

    @collection_persisters[role] = persister
  end

  private def persist_new(class_metadata : AORM::Mapping::ClassInterface, entity : AORM::Entity) : Nil
    # TODO: Handle eventing

    @listeners_invoker.invoke class_metadata, entity, class_metadata.create_pre_persist_event entity.as(AORM::Entity), @em

    id_generator = class_metadata.id_generator

    unless id_generator.post_insert?
      id_value = id_generator.generate @em, entity

      unless id_generator.is_a? ID::AssignedGenerator
        id_key = class_metadata.single_identifier_field_name
        id_value = {id_key => class_metadata.create_column_value(id_key, id_value)}

        class_metadata.set_identifier_values entity, id_value
      end

      # Some identifiers may be foreign keys to new entities.
      # In this case, we don't have the value yet and should treat it as if we have a post-insert generator
      #
      # TODO: Can we just ignore non-hash IDs?
      if !self.has_missing_ids_which_are_foreign_keys?(class_metadata, id_value) && id_value.is_a?(Hash)
        result = Hash(String, Mapping::Value).new
        id_value.each do |k, v|
          result[k] = class_metadata.create_column_value k, v
        end

        @entity_identifiers[entity] = result
      end
    end

    @entity_states[entity] = :managed

    unless @entity_insertions.includes? entity
      self.schedule_for_insert entity
    end
  end

  private def cascade_persist(entity : AORM::Entity, visited : Set(AORM::Entity)) : Nil
    # TODO: Need to know how to skip uninitialized objects?
    # Maybe when we introduce `Ghost`

    class_metadata = @em.class_metadata entity.class

    class_metadata.association_mappings.select { |_, v| v.cascade_persist? }.each_value do |assoc|
      related_entities = class_metadata.get_field_value entity, assoc.field_name

      if related_entities.is_a?(AORM::BasePersistentCollection)
        related_entities = related_entities.unwrap
      end

      if related_entities.is_a?(AORM::BaseCollection) || related_entities.is_a?(Enumerable(AORM::Entity))
        unless assoc.is_a? Mapping::ToMany
          raise "invalid association"
        end

        # Elements arrive typed as their concrete class; upcast so `persist` is compiled once rather than once per entity class.
        related_entities.each do |related_entity|
          self.persist related_entity.as(AORM::Entity), visited if related_entity.is_a?(AORM::Entity)
        end
      elsif !related_entities.nil?
        if related_entities.is_a? AORM::Entity
          self.persist related_entities, visited
        else
          raise "BUG: invalid association"
        end
      end
    end
  end

  private def schedule_for_insert(entity : AORM::Entity) : Nil
    # TODO: Use proper exception classes for these
    raise "Dirty entity cannot be scheduled for insertion" if @entity_updates.includes? entity
    raise "Entity scheduled for deletion" if @entity_deletions.includes? entity
    raise "scheduled insert for managed entity" if @original_entity_data.has_key?(entity) && !@entity_insertions.includes?(entity)
    raise "Entity already scheduled for insertion" unless @entity_insertions.add? entity

    @entity_insertions << entity

    if @entity_identifiers.has_key? entity
      self.add_to_identity_map entity
    end
  end

  # Returns `true` if *entity* will be inserted on the next flush.
  def is_scheduled_for_insert?(entity : AORM::Entity) : Bool
    @entity_insertions.includes? entity
  end

  # :nodoc:
  def schedule_for_delete(entity : AORM::Entity) : Nil
    if @entity_insertions.includes? entity
      if self.is_in_identity_map entity
        self.remove_from_identity_map entity
      end

      @entity_insertions.delete entity
      @entity_states.delete entity

      return
    end

    return unless self.is_in_identity_map entity

    self.remove_from_identity_map entity

    @entity_updates.delete entity

    unless @entity_deletions.includes? entity
      @entity_deletions << entity
      @entity_states[entity] = :removed
    end
  end

  # Returns `true` if *entity* will be deleted on the next flush.
  def is_scheduled_for_delete?(entity : AORM::Entity) : Bool
    @entity_deletions.includes? entity
  end

  # :nodoc:
  def schedule_for_update(entity : AORM::Entity) : Nil
    # TODO: Use proper exception classes for these
    raise "Entity has no identity" unless @entity_identifiers.has_key? entity
    raise "Entity scheduled for deletion" if @entity_deletions.includes? entity

    if !@entity_updates.includes?(entity) && !@entity_insertions.includes?(entity)
      @entity_updates << entity
    end
  end

  # Returns `true` if *entity* changed, and will be updated by the current flush.
  #
  # Like `#scheduled_entity_updates`, this is only known during a flush.
  def is_scheduled_for_update?(entity : AORM::Entity) : Bool
    @entity_updates.includes? entity
  end

  # :nodoc:
  def clear : Nil
    @identity_map.clear
    @entity_identifiers.clear
    @original_entity_data.clear
    @entity_change_sets.clear
    @entity_states.clear
    @entity_insertions.clear
    @entity_updates.clear
    @entity_deletions.clear
    @entity_persisters.clear
    @non_cascaded_new_detected_entities.clear
    @collection_deletions.clear
    @collection_updates.clear
    @extra_updates.clear
    @visited_collections.clear
    @pending_collection_element_removals.clear
    @pending_to_one_resolutions.clear
    @orphan_removals.clear

    @event_dispatcher.try &.dispatch Events::OnClearEventArgs.new @em
  end

  # :nodoc:
  def single_identifier_value(entity : AORM::Entity)
    class_metadata = @em.class_metadata entity.class

    if class_metadata.is_identifier_composite
      raise "illegal composite identifier"
    end

    values = self.is_in_identity_map(entity) ? self.entity_identifier(entity) : class_metadata.identifier_values(entity)

    id = values[class_metadata.identifier.first]?
    return nil if id.nil?

    raw_id = id.is_a?(Mapping::Value) ? id.value : id

    # Identifiers should always be DB-compatible primitive types
    unless raw_id.is_a?(DB::Any)
      raise "BUG: invalid entity identifier value"
    end

    raw_id
  end

  # Returns the `EntityState` of *entity* in relation to this unit of work.
  #
  # Entities that are managed or removed are tracked, so their state is known.
  # For any other entity, *assume* is returned if given.
  # Otherwise *entity* is `EntityState::New` if it has no identifier, and its identifier is looked up in the identity map, and possibly the database, to tell whether it is `EntityState::New` or `EntityState::Detached`.
  def entity_state(entity : AORM::Entity, assume : EntityState? = nil) : EntityState
    if state = @entity_states[entity]?
      return state
    end

    return assume if assume

    # State can only be NEW or DETACHED, because MANAGED/REMOVED states are known.
    # Note that you can not remember the NEW or DETACHED state in _entityStates since
    # the UoW does not hold references to such objects and the object hash can be reused.
    # More generally because the state may "change" between NEW/DETACHED without the UoW being aware of it.
    class_metadata = @em.class_metadata entity.class
    id = class_metadata.identifier_values entity

    if id.empty?
      return EntityState::New
    end

    if class_metadata.contains_foreign_identifier || class_metadata.contains_enum_identifier
      id = self.identifier_flattener.flatten_identifier class_metadata, id
    end

    if class_metadata.identifier_natural?
      # TODO: Handle versioning

      # Last try before DB lookup; check identity map
      self.try_get_by_id id, class_metadata.entity_class do
        return EntityState::Detached
      end

      # Lookup via DB
      if self.entity_persister(class_metadata.entity_class).exists(entity)
        return EntityState::Detached
      end

      return EntityState::New
    elsif !class_metadata.id_generator.post_insert?
      # if we have a pre insert generator we can't be sure that having an id
      # really means that the entity exists. We have to verify this through
      # the last resort: a db lookup

      # Last try before DB lookup; check identity map
      self.try_get_by_id id, class_metadata.entity_class do
        return EntityState::Detached
      end

      # Lookup via DB
      if self.entity_persister(class_metadata.entity_class).exists(entity)
        return EntityState::Detached
      end

      return EntityState::New
    end

    # The identifier is generated on insert, so the entity having one means it was inserted already.
    EntityState::Detached
  end

  # Returns the identifier of *entity*, keyed by field name.
  #
  # Raises if the unit of work doesn't know the identifier of *entity*, such as when it isn't managed, or is new and its identifier is generated on insert.
  def entity_identifier(entity : AORM::Entity) : Hash(String, AORM::Mapping::Value)
    @entity_identifiers[entity]? || raise "Unable to find \"#{entity.class.name}\" entity identifier associated with the UnitOfWork"
  end

  protected def entity_persister(entity_class : AORM::Entity.class) : AORM::Persisters::Entity::Interface
    if persister = @entity_persisters[entity_class]?
      return persister
    end

    class_metadata = @em.class_metadata entity_class

    # TODO: Support other types of persisters
    persister = case class_metadata.inheritance_type
                when .none? then AORM::Persisters::Entity::Basic.new @em, class_metadata
                else
                  raise "No persister found"
                end

    # TODO: Handle caching?

    @entity_persisters[entity_class] = persister
  end

  # :nodoc:
  def get_by_id_hash(id_hash : String, entity_class : AORM::Entity.class) : AORM::Entity?
    @identity_map[entity_class]?.try &.[id_hash]?
  end

  # :nodoc:
  def try_get_by_id(id : Hash(String, _), entity_class : AORM::Entity.class, &) : Nil
    id_hash = self.class.id_hash_by_identifier(id)

    if (klass = @identity_map[entity_class]?) && (entity = klass[id_hash]?)
      yield entity
    end
  end

  # :nodoc:
  def add_to_identity_map(entity : AORM::Entity) : Bool
    class_metadata = @em.class_metadata self.metadata_class_for(entity)
    id_hash = self.id_hash_of_entity entity
    entity_class = class_metadata.entity_class

    if @identity_map.has_key?(entity_class) && @identity_map[entity_class].has_key?(id_hash)
      if @identity_map[entity_class][id_hash] != entity
        raise "entity identity collision"
      end

      return false
    end

    (@identity_map[entity_class] ||= Hash(String, AORM::Entity).new)[id_hash] = entity

    true
  end

  # :nodoc:
  def id_hash_of_entity(entity : AORM::Entity) : String
    identifier = @entity_identifiers[entity]?

    if !identifier || identifier.empty? || identifier.values.any?(&.value.nil?)
      raise "entity without identity"
    end

    self.class.id_hash_by_identifier identifier
  end

  # Returns `true` if *entity* is registered in the identity map.
  #
  # Entities are registered once their identifier is known: when they are loaded, when a new entity with an assigned identifier is persisted, or when a generated identifier is read back on insert.
  def is_in_identity_map(entity : AORM::Entity) : Bool
    return false if !@entity_identifiers.has_key?(entity) || @entity_identifiers[entity].empty?

    class_metadata = @em.class_metadata self.metadata_class_for(entity)
    id_hash = self.id_hash_of_entity entity

    # p({
    #   entity:          entity,
    #   in_identity_map: @identity_map.has_key?(class_metadata.entity_class) && @identity_map[class_metadata.entity_class].has_key?(id_hash),
    #   identity_map:    @identity_map,
    #   id_hash:         id_hash,
    #   entity_class:    class_metadata.entity_class,
    # })

    @identity_map.has_key?(class_metadata.entity_class) && @identity_map[class_metadata.entity_class].has_key?(id_hash)
  end

  # :nodoc:
  def remove_from_identity_map(entity : AORM::Entity) : Bool
    class_metadata = @em.class_metadata self.metadata_class_for(entity)
    id_hash = self.id_hash_of_entity entity

    # TODO: Use proper exception type
    raise "Entity has no identity" if id_hash.empty?

    if (identity = @identity_map[class_metadata.entity_class]?) && identity.has_key?(id_hash)
      identity.delete id_hash

      return true
    end

    false
  end

  # Returns the changes the current flush computed for *entity*, as a `Change` per field name.
  #
  # Includes mapped fields and the owning side of ToOne associations, whose values are the related entities.
  # Entities being inserted have a change, with a `nil` `Change#old`, for each field their INSERT writes.
  # Returns an empty hash if *entity* has no changes, or outside of a flush, since change sets are cleared once it completes.
  def entity_changeset(entity : AORM::Entity) : Hash
    unless cs = @entity_change_sets[entity]?
      return {} of String => NoReturn
    end

    cs
  end

  # :nodoc:
  #
  # Schedules a follow-up UPDATE to apply the given changeset to *entity*. Used
  # by persisters when a FK can't be written at INSERT time because the
  # referenced entity hasn't been inserted yet (cyclic dependency). Multiple
  # extra updates for the same entity are merged.
  def schedule_extra_update(entity : AORM::Entity, changeset : Hash(String, Change)) : Nil
    if existing = @extra_updates[entity]?
      @extra_updates[entity] = existing.merge changeset
    else
      @extra_updates[entity] = changeset
    end
  end

  # :nodoc:
  def extra_update_for(entity : AORM::Entity) : Hash(String, Change)
    @extra_updates[entity]? || Hash(String, Change).new
  end

  private def execute_extra_updates : Nil
    @extra_updates.each do |entity, changeset|
      # Swap the entity's main changeset out for the extra one so the persister's
      # update path writes only the patched columns.
      @entity_change_sets[entity] = changeset
      self.entity_persister(entity.class).update entity
    end

    @extra_updates.clear
  end

  # :nodoc:
  def compute_changesets : Nil
    self.compute_scheduled_inserts_change_sets

    @identity_map.each do |entity_class, entity_hash|
      class_metadata = @em.class_metadata entity_class

      next if class_metadata.read_only?

      # TODO: Handle change tracking policies

      entity_hash.each_value do |entity|
        # Ignore unloaded proxies; their target hasn't been loaded, so it can't have changed.
        next if self.uninitialized_object? entity

        # Only MANAGED entities that are NOT SCHEDULED FOR INSERTION OR DELETION are processed here.
        if !@entity_insertions.includes?(entity) && !@entity_deletions.includes?(entity) && @entity_states.has_key?(entity)
          self.compute_change_set class_metadata, entity
        end
      end
    end
  end

  # Returns `true` if *entity* is a proxy whose target hasn't been loaded yet.
  private def uninitialized_object?(entity : AORM::Entity) : Bool
    entity.is_a?(AORM::Proxy) && !entity.loaded?
  end

  private def compute_scheduled_inserts_change_sets : Nil
    @entity_insertions.each do |entity|
      class_metadata = @em.class_metadata entity.class

      self.compute_change_set class_metadata, entity
    end
  end

  # Computes the change set of the managed *entity*, comparing its current state with the data it was loaded or last flushed with.
  # The change set of an entity being inserted holds every field its `INSERT` writes.
  #
  # Change sets are computed at the start of a flush, before `AORM::Events::OnFlushEventArgs` is dispatched.
  # So a listener of that event that persists an entity also has to compute its change set:
  #
  # ```
  # em.persist phone
  # em.unit_of_work.compute_change_set em.class_metadata(Phone), phone
  # ```
  def compute_change_set(class_metadata : AORM::Mapping::ClassInterface, entity : AORM::Entity) : Nil # ameba:disable Metrics/CyclomaticComplexity
    # TODO: Handle readonly objects

    unless class_metadata.inheritance_type.none?
      class_metadata = @em.class_metadata entity.class
    end

    @listeners_invoker.invoke class_metadata, entity, Events::PreFlushEventArgs.new @em

    actual_data = Hash(String, Mapping::Value).new

    class_metadata.field_info.each do |name, _prop|
      # Instance variables that aren't mapped aren't persisted.
      next unless class_metadata.field_mappings.has_key?(name) || class_metadata.association_mappings.has_key?(name)

      if (assoc = class_metadata.association_mappings[name]?) && assoc.is_a?(Mapping::ToMany)
        # Promote a user-assigned ArrayCollection (or a PersistentCollection owned by another entity) into a PersistentCollection owned by this entity.
        next if class_metadata.get_field_value(entity, name).nil?

        target_metadata = @em.class_metadata assoc.target_entity
        p_coll = class_metadata.promote_collection name, entity, @em, target_metadata, assoc
        actual_data[name] = class_metadata.create_column_value name, p_coll
        next
      end

      # TODO: Handle versioning
      if (!class_metadata.is_identifier(name) || !class_metadata.identifier_identity?) && true
        actual_data[name] = class_metadata.create_column_value_from_entity name, entity
      end
    end

    if original_data = @original_entity_data[entity]?
      change_set = Hash(String, Change).new

      actual_data.each do |prop_name, actual_value|
        # Skip partially omitted fields
        next unless original_data.has_key? prop_name

        original_value = original_data[prop_name].value
        actual_inner = actual_value.value

        # TODO: Handle enum types

        next if original_value == actual_inner

        # Regular field
        unless assoc = class_metadata.association_mappings[prop_name]?
          change_set[prop_name] = class_metadata.create_change prop_name, original_value, actual_inner

          next
        end

        if actual_inner.is_a?(AORM::BasePersistentCollection)
          raise "BUG: Not ToMany assoc" unless assoc.is_a? Mapping::ToMany
          owner = actual_inner.owner

          if owner.nil?
            actual_inner.set_owner entity, assoc
          elsif owner != entity
            # Force lazy load before cloning so the new owner doesn't share backing state with the original
            actual_inner.initialize_collection

            new_value = actual_inner.clone
            new_value.set_owner entity, assoc
            # Widen to `AORM::BaseCollection` here so `set_field_value` doesn't fan out to one specialization per `PersistentCollection(T)` member of `actual_inner.clone`'s inferred return union.
            class_metadata.set_field_value entity, assoc.field_name, new_value.as(AORM::BaseCollection)
          end
        end

        if original_value.is_a?(AORM::BasePersistentCollection)
          unless @collection_deletions.includes? original_value
            @collection_deletions << original_value
          end

          next
        end

        if assoc.is_a? Mapping::ToOne
          if assoc.is_a? Mapping::OwningSide
            change_set[prop_name] = class_metadata.create_change prop_name, original_value, actual_inner
          end

          if original_value.is_a?(AORM::Entity) && assoc.orphan_removal?
            self.schedule_orphan_removal original_value
          end
        end
      end

      unless change_set.empty?
        @entity_change_sets[entity] = change_set
        @original_entity_data[entity] = actual_data.transform_values { |v, k| class_metadata.create_column_value k, v }
        @entity_updates << entity
      end
    else
      # Entity is NEW or MANAGED but not yet fully persisted (only has an id).
      # These result in an INSERT

      @original_entity_data[entity] = actual_data.transform_values { |v, k| class_metadata.create_column_value k, v }
      change_set = Hash(String, Change).new

      actual_data.each do |prop_name, actual_value|
        unless assoc = class_metadata.association_mappings[prop_name]?
          change_set[prop_name] = class_metadata.create_change prop_name, nil, actual_value.value

          next
        end

        if assoc.is_a? Mapping::ToOneOwningSide
          change_set[prop_name] = class_metadata.create_change prop_name, nil, actual_value.value
        end
      end

      @entity_change_sets[entity] = change_set
    end

    class_metadata.association_mappings.each do |field, assoc|
      value = class_metadata.get_field_value entity, field
      next if value.nil?

      self.compute_association_changes assoc, value

      if assoc.is_a?(Mapping::ManyToManyOwningSide) && value.is_a?(AORM::BasePersistentCollection) && value.dirty?
        @collection_updates << value
        @visited_collections << value
      end
    end
  end

  # Compute association changeset
  private def compute_association_changes(assoc : AORM::Mapping::Association, value) : Nil
    unwrapped_value = if assoc.is_a?(Mapping::ToMany)
                        # Iterate the backing collection without forcing a lazy load via `unwrap` that returns the inner ArrayCollection whether the PC is initialized or not.
                        # Uninitialized collections are simply empty.
                        if value.is_a?(AORM::BasePersistentCollection)
                          value.unwrap.to_a
                        else
                          raise "BUG: ToMany value is not iterable (#{value.class})"
                        end
                      elsif value.is_a?(AORM::Proxy)
                        # ToOne lazy: walk a loaded proxy's inner entity.
                        # An unloaded proxy points at an already-persisted target, so there's nothing new to cascade.
                        (inner = value.inner?) ? [inner.as(AORM::Entity)] : ([] of AORM::Entity)
                      elsif value.is_a?(AORM::Entity)
                        # ToOne eager: wrap single entity in array
                        [value]
                      else
                        raise "BUG: ToOne value is not an entity"
                      end

    target_class_metadata = @em.class_metadata assoc.target_entity

    unwrapped_value.each_with_index do |entity, _|
      raise "BUG: unwrapped_value is not an entity" unless entity.is_a? AORM::Entity

      case self.entity_state(entity, EntityState::New)
      when .new?
        unless assoc.cascade_persist?
          # For now just record the details, because this may not be an issue if we later discover another pathway
          # through the object-graph where cascade-persistence is enabled for this object.
          @non_cascaded_new_detected_entities[entity] = {assoc, entity}
          next
        end

        self.persist_new target_class_metadata, entity
        self.compute_change_set target_class_metadata, entity
      when .removed?
        next unless assoc.is_a? Mapping::ToMany
        raise "BUG: value for ToMany assoc is not a collection" unless value.is_a?(AORM::BaseCollection)

        @visited_collections << value

        # Defer the in-memory removal until after the transaction commits, so a
        # rollback leaves the collection's view of its elements unchanged.
        if value.is_a? AORM::BasePersistentCollection
          pending = @pending_collection_element_removals[value] ||= [] of AORM::Entity
          pending << entity
        end
      else
        # noop
      end
    end
  end

  # Recomputes the change set of the managed *entity*, independently of the change sets computed at the start of a flush.
  # The changes it finds are added to the entity's change set, and schedule it to be updated if it isn't already.
  # Raises if *entity* isn't managed.
  #
  # Change sets are computed before `AORM::Events::OnFlushEventArgs` is dispatched, so a listener of that event that changes the fields of a managed entity recomputes its change set:
  #
  # ```
  # user.name = "George"
  # em.unit_of_work.recompute_single_entity_change_set em.class_metadata(User), user
  # ```
  #
  # Changes to the entity's collections aren't recomputed.
  def recompute_single_entity_change_set(class_metadata : AORM::Mapping::ClassInterface, entity : AORM::Entity) : Nil
    raise "Entity is not managed" unless @entity_states[entity]? == EntityState::Managed

    unless class_metadata.inheritance_type.none?
      class_metadata = @em.class_metadata entity.class
    end

    actual_data = Hash(String, Mapping::Value).new

    class_metadata.field_info.each do |name, _prop|
      # Instance variables that aren't mapped aren't persisted.
      next unless class_metadata.field_mappings.has_key?(name) || class_metadata.association_mappings.has_key?(name)
      next if (assoc = class_metadata.association_mappings[name]?) && assoc.is_a?(Mapping::ToMany)

      # TODO: Skip version field
      if !class_metadata.is_identifier(name) || !class_metadata.identifier_identity?
        actual_data[name] = class_metadata.create_column_value_from_entity name, entity
      end
    end

    unless original_data = @original_entity_data[entity]?
      raise "Cannot call recompute_single_entity_change_set before compute_change_set on an entity"
    end

    change_set = Hash(String, Change).new

    actual_data.each do |prop_name, actual_value|
      original_value = original_data[prop_name]?.try &.value
      actual_inner = actual_value.value

      # TODO: Handle enum types

      next if original_value == actual_inner

      change_set[prop_name] = class_metadata.create_change prop_name, original_value, actual_inner
    end

    unless change_set.empty?
      if existing = @entity_change_sets[entity]?
        @entity_change_sets[entity] = existing.merge change_set
      elsif !@entity_insertions.includes?(entity)
        @entity_change_sets[entity] = change_set
        @entity_updates << entity
      end

      @original_entity_data[entity] = actual_data
    end
  end

  # :nodoc:
  def schedule_orphan_removal(entity : AORM::Entity) : Nil
    @orphan_removals.add entity
  end

  # :nodoc:
  def cancel_orphan_removal(entity : AORM::Entity) : Nil
    @orphan_removals.delete entity
  end

  # :nodoc:
  def trigger_eager_loads : Nil
    # TODO: Implement this
  end

  # :nodoc:
  #
  # Creates or retrieves an entity from hydrated data, returning the
  # identity-mapped instance when one already exists for this id_hash.
  def create_entity(
    entity_class : AORM::Entity.class,
    data : Hash,
    hints : AORM::Query::Hints = AORM::Query::Hints.new,
  ) : AORM::Entity
    class_metadata = @em.class_metadata entity_class

    id = identifier_flattener.flatten_identifier(class_metadata, data)
    id_hash = self.class.id_hash_by_identifier id

    # Check identity map for existing entity
    if (class_map = @identity_map[class_metadata.entity_class]?) && (entity = class_map[id_hash]?)
      # TODO: Know if entity is uninitialized?

      if hints.refresh?
        # Re-apply scalar fields from the freshly fetched row data and reset
        # the changeset baseline so the EM no longer sees pending changes.
        class_metadata.apply_data entity, data

        # Only mapped fields are refreshed: the row also carries foreign key columns, and associations aren't reloaded, so their baselines stay as they were.
        original_data = @original_entity_data[entity]
        data.each do |field_name, value|
          next unless class_metadata.field_mappings.has_key? field_name
          original_data[field_name] = class_metadata.create_column_value(field_name, value).as Mapping::Value
        end
        @entity_change_sets.delete entity
        @entity_updates.delete entity
      end

      return entity
    end

    # This also handles setting ivars based on the data
    entity = class_metadata.new_instance(data)
    self.register_managed(entity, id, data)
    # TODO: Handle readonly hints

    # TODO: Handle eager loading entities

    # Initialize collections with owner and association metadata so they can lazy-load.
    class_metadata.association_mappings.each do |field_name, assoc|
      # TODO: Handle fetchAlias/fetchMode hints

      target_class_metadata = @em.class_metadata assoc.target_entity

      if assoc.is_a? Mapping::ToOne
        self.handle_to_one_during_hydration(class_metadata, entity, field_name, assoc, data)
      else
        raise "BUG: Assoc is not ToMany" unless assoc.is_a? Mapping::ToMany

        # TODO: Handle PersistentCollection in `data`

        # Do this here so `T` can be properly resolved
        # pp entity.class, target_class_metadata.class, assoc.class
        p_coll = class_metadata.inject_collection field_name, entity, @em, target_class_metadata, assoc

        # TODO: Handle eager fetching hints

        @original_entity_data[entity][field_name] = class_metadata.create_column_value field_name, p_coll
      end
    end

    # TODO: Handle deferring postLoad event

    entity
  end

  # :nodoc:
  #
  # Registers an entity as managed in the UnitOfWork.
  def register_managed(entity : AORM::Entity, id : Hash(String, _), data : Hash(String, _)) : Nil
    class_metadata = @em.class_metadata(entity.class)

    @entity_identifiers[entity] = id.transform_values { |v, k| class_metadata.create_column_value(k, v).as Mapping::Value }
    @entity_states[entity] = :managed

    # `data` may contain meta-mapping entries (FK column names) that don't correspond to entity fields — only persist values keyed by something the entity actually has an ivar for.
    typed_data = Hash(String, Mapping::Value).new
    data.each do |k, v|
      next unless class_metadata.field_info.has_key? k
      typed_data[k] = class_metadata.create_column_value(k, v).as Mapping::Value
    end
    @original_entity_data[entity] = typed_data

    self.add_to_identity_map(entity)
  end

  # Resolves a ToOne association during `create_entity`.
  # For owning side, reads the FK from the row data; identity-map hits resolve immediately, misses are queued for the hydrator's `cleanup` to avoid running a nested query while the main cursor is still active.
  # Inverse side is always queued.
  private def handle_to_one_during_hydration(
    class_metadata : Mapping::ClassInterface,
    entity : AORM::Entity,
    field_name : String,
    assoc : Mapping::ToOne,
    data : Hash,
  ) : Nil
    if assoc.is_a?(Mapping::ToOneOwningSide)
      target_class_metadata = @em.class_metadata assoc.target_entity
      associated_id = self.build_associated_id_from_row_data assoc, target_class_metadata, data

      if associated_id.nil?
        # FK is null. Property's default value (typed `Target?`) is already nil;
        # record that in original_entity_data so change tracking sees it.
        @original_entity_data[entity][field_name] = class_metadata.create_column_value_from_entity field_name, entity
        return
      end

      # Identity-map hit: resolve inline — no query needed.
      related_id_hash = self.class.id_hash_by_identifier associated_id
      if (target_map = @identity_map[target_class_metadata.entity_class]?) && (existing = target_map[related_id_hash]?)
        # On a `AORM::Proxy(T)?`-typed field the ivar can't hold a raw `T`, so wrap the existing entity in a loaded proxy.
        # The canonical record stays in the identity map untouched; the proxy is a per-field façade.
        target = assoc.lazy_proxy? ? self.wrap_in_proxy(target_class_metadata.entity_class, existing) : existing
        self.assign_to_one_target class_metadata, entity, field_name, assoc, target
        return
      end

      db_id = associated_id.transform_values do |v|
        raw = v.is_a?(Mapping::Value) ? v.value : v
        raise "BUG: associated id value is not DB-compatible: #{raw.inspect}" unless raw.is_a?(DB::Any)
        raw.as(DB::Any)
      end

      # Miss with `Proxy(T)?` typing: install an unloaded proxy and register it as the canonical record under the target's id.
      # The proxy stays in the identity map until it's first accessed, at which point `Proxy#inner` removes it before the persister loads the real entity (which then re-registers under the same key).
      if assoc.lazy_proxy?
        proxy = self.build_proxy @em, target_class_metadata.entity_class, db_id
        proxy_identifiers = associated_id.transform_values do |v, k|
          target_class_metadata.create_column_value(k, v).as Mapping::Value
        end
        @entity_identifiers[proxy] = proxy_identifiers
        @entity_states[proxy] = :managed
        self.add_to_identity_map proxy
        self.assign_to_one_target class_metadata, entity, field_name, assoc, proxy
        return
      end

      # Miss with plain `Target?`: defer to hydrator cleanup.
      @pending_to_one_resolutions << PendingToOneResolution.new(entity, field_name, assoc.target_entity, db_id)
    else
      # Inverse side: always eager via persister. Defer the SELECT to cleanup.
      raise "BUG: ToOne assoc is neither owning nor inverse side" unless assoc.is_a?(Mapping::InverseSide)
      @pending_to_one_resolutions << PendingToOneResolution.new(entity, field_name, assoc.target_entity, nil)
    end
  end

  # Reads FK column values out of *data* (keyed by the FK column name, the way
  # the hydrator's meta-mapping branch deposited them) and returns the target's
  # identifier hash, or nil if any column is null (treat the entire FK as null).
  private def build_associated_id_from_row_data(
    assoc : Mapping::ToOneOwningSide,
    target_class_metadata : Mapping::ClassInterface,
    data : Hash,
  ) : Hash(String, DB::Any)?
    associated_id = Hash(String, DB::Any).new

    assoc.target_to_source_key_columns.each do |target_column, source_column|
      value = data[source_column]?
      raw = value.is_a?(Mapping::Value) ? value.value : value

      if raw.nil?
        # If any FK column is null, treat the whole reference as null.
        return nil
      end

      target_field_name = target_class_metadata.field_names[target_column]?
      raise "BUG: Target column '#{target_column}' not mapped on #{target_class_metadata.entity_class}" unless target_field_name

      raise "BUG: associated id value is not DB-compatible: #{raw.inspect}" unless raw.is_a?(DB::Any)
      associated_id[target_field_name] = raw.as(DB::Any)
    end

    associated_id.empty? ? nil : associated_id
  end

  # :nodoc:
  #
  # Walks any ToOne resolutions queued during hydration and writes the loaded target onto its source entity.
  # Called by the hydrator's `cleanup` once the main result-set cursor has closed.
  def resolve_pending_to_one_associations : Nil
    return if @pending_to_one_resolutions.empty?

    pending = @pending_to_one_resolutions
    @pending_to_one_resolutions = [] of PendingToOneResolution

    pending.each do |resolution|
      source = resolution.source
      source_class_metadata = @em.class_metadata source.class
      assoc = source_class_metadata.association_mappings[resolution.field_name]
      raise "BUG: pending resolution references non-ToOne association" unless assoc.is_a?(Mapping::ToOne)

      target = if id = resolution.target_id
                 # An earlier resolution in this batch may have already loaded
                 # the same target — re-check the identity map before issuing a
                 # SELECT.
                 existing : AORM::Entity? = nil
                 self.try_get_by_id(id, resolution.target_class) { |e| existing = e }
                 existing || self.entity_persister(resolution.target_class).load(id)
               else
                 raise "BUG: inverse-side pending resolution but assoc isn't InverseSide" unless assoc.is_a?(Mapping::InverseSide)
                 self.entity_persister(assoc.target_entity).load_one_to_one_entity assoc, source
               end

      next if target.nil?

      self.assign_to_one_target source_class_metadata, source, resolution.field_name, assoc, target
    end
  end

  # Writes a resolved ToOne target entity onto its source via the macro-driven
  # `apply_data` (so the dispatch lands on the right ivar type), updates the
  # original-data baseline for change tracking, and applies the OneToOne
  # `inversed_by` back-pointer when relevant.
  private def assign_to_one_target(
    source_class_metadata : Mapping::ClassInterface,
    source : AORM::Entity,
    field_name : String,
    assoc : Mapping::Association,
    target : AORM::Entity,
  ) : Nil
    source_class_metadata.apply_data source, {field_name => target}

    @original_entity_data[source][field_name] = source_class_metadata.create_column_value_from_entity field_name, source

    # OneToOne owning-side: reflect the bidirectional link on the inverse end.
    return unless assoc.is_a?(Mapping::OneToOneOwningSide)
    inversed_by = assoc.inversed_by
    return unless inversed_by

    # Skip when the target is an unloaded proxy: the proxy doesn't carry the inverse-side ivar, and the back-pointer will be resolved when the proxy loads and the real entity hydrates from its own row.
    return if target.is_a?(AORM::Proxy)

    target_class_metadata = @em.class_metadata target.class
    return unless target_class_metadata.field_info.has_key? inversed_by

    target_class_metadata.apply_data target, {inversed_by => source}
  end

  # :nodoc:
  def load_collection(collection : AORM::BasePersistentCollection) : Nil
    assoc = collection.association
    persister = self.entity_persister(assoc.target_entity)

    # The persister hydrates straight into the collection via the `:collection`
    # hydrator hint, so there's nothing to re-add here.
    case assoc
    when Mapping::ManyToMany
      persister.load_many_to_many_collection(assoc, collection.owner.not_nil!, collection)
    when Mapping::OneToMany
      persister.load_one_to_many_collection(assoc, collection.owner.not_nil!, collection)
    end

    collection.initialized = true
  end

  private def has_missing_ids_which_are_foreign_keys?(class_metadata : Mapping::ClassInterface, id : Hash(String, _)) : Bool
    id.any? do |id_field, id_field_value|
      value = id_field_value.is_a?(Mapping::Value) ? id_field_value.value : id_field_value

      value.nil? && class_metadata.association_mappings.has_key? id_field
    end
  end

  private def has_missing_ids_which_are_foreign_keys?(class_metadata : Mapping::ClassInterface, id : _) : Bool
    false
  end

  # Returns the class to look up `ClassMetadata` against.
  # For proxies this is the wrapped target type; for regular entities it's `entity.class`.
  private def metadata_class_for(entity : AORM::Entity) : AORM::Entity.class
    entity.is_a?(AORM::Proxy) ? entity.target_class : entity.class
  end

  # Builds an unloaded proxy for a ToOne owning-side miss whose target is typed `Proxy(...)?`.
  private def build_proxy(em : AORM::EntityManagerInterface, target_class : AORM::Entity.class, id : Hash(String, ::DB::Any)) : AORM::Entity
    raise "BUG: build_proxy called for #{target_class} but no Proxy(#{target_class}) overload was generated"
  end

  # Wraps an already-loaded entity in a `Proxy(T)` so it can be assigned to a `Proxy(T)?`-typed field on an owner whose lazy_proxy ToOne hit the identity map.
  # The wrapped proxy is a per-field façade — the canonical record under the target's id stays untouched.
  private def wrap_in_proxy(target_class : AORM::Entity.class, value : AORM::Entity) : AORM::Entity
    raise "BUG: wrap_in_proxy called for #{target_class} but no Proxy(#{target_class}) overload was generated"
  end

  # The dispatchers below create a `Proxy(T)` for every entity, and each new one is a subclass of `AORM::Entity` that re-types every call already typed through `AORM::Entity` or `AORM::Entity.class`.
  # Methods whose body depends on the receiver class, such as `Class#to_s`, are typed again for each existing proxy class every time, which made compile time grow quadratically with the number of entities.
  # Declaring the proxy type of every entity before any code is typed avoids that.
  macro finished
    {% for entity, idx in Athena::ORM::Entity.all_subclasses.reject { |t| t.abstract? || t <= Athena::ORM::Proxy } %}
      @@proxy_{{idx}} : AORM::Proxy({{entity.id}})? = nil

      private def build_proxy(em : AORM::EntityManagerInterface, target_class : {{entity.id}}.class, id : Hash(String, ::DB::Any)) : AORM::Entity
        AORM::Proxy({{entity.id}}).from_id em, id
      end

      private def wrap_in_proxy(target_class : {{entity.id}}.class, value : AORM::Entity) : AORM::Entity
        AORM::Proxy({{entity.id}}).wrap value.as({{entity.id}})
      end
    {% end %}
  end
end
