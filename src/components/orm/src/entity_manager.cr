require "./entity_manager_interface"

# The central access point to the ORM, used to persist, find, and remove entities.
#
# ```
# em = AORM::EntityManager.new connection
#
# user = User.new
# user.name = "George"
#
# em.persist user
# em.flush
#
# user.id # => 1
#
# em.find(User, 1).same? user # => true
# ```
#
# An entity manager tracks the entities it loads or is given in a unit of work, and isn't safe to share between fibers.
# Use an `AORM::EntityManagerFactory` to create one for each unit of work, such as a request or a job.
#
# ## Writing Changes
#
# Only `#flush` writes to the database.
# Methods such as `#persist` and `#remove` only schedule an entity to be inserted or deleted, and changes to the entities' properties are detected when flushing.
# `#flush` then writes all of the pending changes in a single transaction, ordering the statements so that the rows referenced by foreign keys exist before the rows referencing them.
# Don't make assumptions about the number or order of the statements a flush executes.
#
# There's no need to tell the entity manager about changes to an entity it manages:
#
# ```
# user = em.find! User, 1
# user.name = "Jim"
#
# em.flush # => UPDATE users SET name = ? WHERE id = ?
# ```
#
# Prefer flushing once a unit of work is done over flushing after every change, since each flush computes the changes of every managed entity.
#
# ## Identity Map
#
# An entity manager holds at most one instance of each entity, keyed by its identifier.
# Finding an entity that's already been loaded returns the same instance without querying the database, whichever way it's loaded:
#
# ```
# user = em.find! User, 1
# user.name = "Jim"
#
# em.repository(User).find_one_by(name: "Jim").same? user # => true
# ```
#
# Since a loaded entity isn't overwritten by later queries, unflushed changes are kept.
# Use `#refresh` to reload an entity, or `#clear` to start over with an empty identity map.
#
# ## Entity States
#
# An entity is in one of the states of `AORM::UnitOfWork::EntityState` in relation to an entity manager:
#
# * **New** - It has no persistent identity, and isn't associated with the entity manager yet, such as an entity that was just instantiated.
# * **Managed** - It's associated with the entity manager, which writes its changes to the database when flushing.
# * **Removed** - It's associated with the entity manager, and will be deleted when flushing.
# * **Detached** - It has a persistent identity, but isn't associated with the entity manager anymore, such as after `#clear`.
#
# The effects of `#persist`, `#remove`, and `#detach` depend on the entity's state, as described on each method.
#
# ## Transactions
#
# Each `#flush` runs in its own transaction, so a failed flush leaves the database unchanged.
# When a flush fails, the entity manager is also closed, and should be discarded along with its entities, whose state no longer matches the database.
#
# Wrap more work in one transaction via `#wrap_in_transaction`, or with `#begin_transaction`, `#commit`, and `#rollback`:
#
# ```
# em.wrap_in_transaction do
#   user = em.find! User, 1
#   user.balance -= 100
#
#   em.connection.exec "INSERT INTO audit_log (message) VALUES (?)", "Withdrew 100"
# end
# ```
#
# Transactions nest; a transaction started while another is active is a savepoint within it.
# A flush in an explicit transaction therefore only rolls back its own savepoint if it fails.
class Athena::ORM::EntityManager
  include Athena::ORM::EntityManagerInterface

  # :inherit:
  getter connection : AORM::Connection

  # :inherit:
  getter? closed : Bool = false

  # :inherit:
  getter unit_of_work : AORM::UnitOfWork { AORM::UnitOfWork.new self }

  # :nodoc:
  getter! metadata_factory : AORM::Mapping::ClassFactory

  @repository_factory : AORM::RepositoryFactoryInterface

  # Returns the event dispatcher the flush and clear events are dispatched to, if any.
  getter event_dispatcher : ACTR::EventDispatcher::Interface?

  # Creates an entity manager executing its queries on *connection*.
  #
  # *event_dispatcher* receives the `Events::PreFlushEventArgs`, `Events::OnFlushEventArgs`, `Events::PostFlushEventArgs` and `Events::OnClearEventArgs` events.
  # Per-entity events, such as `Events::PrePersistEventArgs`, are only delivered to the entity's lifecycle callbacks.
  #
  # *metadata_cache* shares class metadata with other entity managers on the same database; without one, metadata is built for this entity manager alone.
  def initialize(
    connection : DB::Connection,
    @event_dispatcher : ACTR::EventDispatcher::Interface? = nil,
    *,
    metadata_cache : AORM::Mapping::MetadataCache? = nil,
  )
    @connection = AORM::Connection.new(connection)
    @repository_factory = AORM::DefaultRepositoryFactory.new

    metadata_factory = AORM::Mapping::ClassFactory.new
    metadata_factory.entity_manager = self
    metadata_factory.cache = metadata_cache

    @metadata_factory = metadata_factory
  end

  # Returns the entity of type *entity_class* with the identifier *id*, or `nil` if there isn't one.
  #
  # ```
  # em.find User, 1 # => #<User:0x7f3a1c2b5e40 @id=1, @name="George">
  # em.find User, 2 # => nil
  # ```
  #
  # An entity in the identity map is returned without querying the database.
  # Entities with a composite identifier are found with a `Hash` holding a value for each identifier field, see [Composite Keys][Athena::ORM::Annotations::ID--composite-keys].
  # Raises an `AORM::Exceptions::MissingIdentifierField` if the hash is missing a field, or if a single value is given for a composite identifier.
  #
  # TODO: Row locking isn't supported yet, see `AORM::LockMode`.
  def find(
    entity_class : T.class,
    id : Hash(String, Int | String) | Int | String,
    lock_mode : AORM::LockMode = :none,
    lock_version : Int32? = nil,
  ) : AORM::Entity? forall T
    {% raise "entity_class must be an AORM::Entity.class, not '#{T}'." unless T <= AORM::Entity %}

    # Only the result cast depends on *T*, so the lookup itself is shared by every entity class.
    self.find_entity(entity_class.as(AORM::Entity.class), id, lock_mode, lock_version).as T?
  end

  private def find_entity(
    entity_class : AORM::Entity.class,
    id : Hash(String, Int | String) | Int | String,
    lock_mode : AORM::LockMode,
    lock_version : Int32?,
  ) : AORM::Entity?
    class_metadata = self.class_metadata entity_class
    entity_class = class_metadata.entity_class

    # TODO: Handle locking

    if id.is_a? Hash
      missing = class_metadata.identifier.reject { |field| id.has_key? field }
      unless missing.empty?
        raise AORM::Exceptions::MissingIdentifierField.new entity_class, missing
      end
    else
      if class_metadata.identifier.size > 1
        raise AORM::Exceptions::MissingIdentifierField.new entity_class,
          "scalar id passed for composite primary key (fields: #{class_metadata.identifier.to_a.join(", ")})"
      end
      id = {class_metadata.single_identifier_field_name => id}
    end

    uow = self.unit_of_work

    uow.try_get_by_id(id, entity_class) do |entity|
      # An unloaded proxy stands in for the entity in the identity map, but isn't an instance of its class.
      # Loading it through the proxy keeps the proxy and the identity map pointing at the same entity.
      entity = entity.inner.as(AORM::Entity) if entity.is_a?(AORM::Proxy)

      # Compared by type id, since comparing two arbitrary entity classes with `!=` compiles to a branch for every pair of entity classes.
      return nil if entity.class.crystal_type_id != entity_class.crystal_type_id

      # TODO: Handle locking

      return entity
    end

    persister = uow.entity_persister entity_class

    # TODO: Handle locking

    persister.load_by_id(id)
  end

  # Returns the entity of type *entity_class* with the identifier *id*.
  # Raises an `AORM::Exceptions::NoResult` if there isn't one.
  #
  # See `#find`.
  def find!(
    entity_class : T.class,
    id : Hash(String, Int | String) | Int | String,
    lock_mode : AORM::LockMode = :none,
    lock_version : Int32? = nil,
  ) : AORM::Entity forall T
    self.find(entity_class, id, lock_mode, lock_version) || raise AORM::Exceptions::NoResult.new
  end

  # :inherit:
  def persist(entity : AORM::Entity) : Nil
    # The entry points upcast entities to `AORM::Entity` so the unit of work compiles its internals once, rather than once per entity class (each copy dispatching over every entity class again).
    self.unless_closed do
      self.unit_of_work.persist entity.as(AORM::Entity)
    end
  end

  # :inherit:
  def remove(entity : AORM::Entity) : Nil
    self.unless_closed do
      self.unit_of_work.remove entity.as(AORM::Entity)
    end
  end

  # :inherit:
  def refresh(entity : AORM::Entity, lock_mode : AORM::LockMode = :none) : Nil
    self.unless_closed do
      self.unit_of_work.refresh entity.as(AORM::Entity), lock_mode
    end
  end

  # Detaches the managed *entity* from this entity manager, which then no longer writes its changes to the database or returns it from the identity map.
  # Pending changes that weren't flushed are discarded, including a scheduled insert or deletion.
  #
  # Entities that aren't managed are ignored.
  # The operation is also applied to the associated entities of associations that cascade `"detach"`.
  # Other entities that reference *entity* keep referencing it.
  def detach(entity : AORM::Entity) : Nil
    self.unless_closed do
      self.unit_of_work.detach entity.as(AORM::Entity)
    end
  end

  # :inherit:
  def flush : Nil
    self.unless_closed do
      self.unit_of_work.commit
    end
  end

  # :inherit:
  def clear : Nil
    self.unit_of_work.clear
  end

  # Returns the mapping metadata of *entity_class*.
  def class_metadata(for entity_class : AORM::Entity.class) : AORM::Mapping::ClassInterface
    self.metadata_factory.metadata entity_class
  end

  # Each overload upcasts the class so the repository factory is compiled once rather than once per entity class.
  macro finished
    {% for entity in Athena::ORM::Entity.all_subclasses.reject { |t| t.abstract? || t <= Athena::ORM::Proxy } %}
      {% entity_ann = entity.annotation(AORMA::Entity) %}
      {% repository_class = entity_ann && entity_ann[:repository_class] %}
      {% if repository_class %}
        # Custom-repo overload: `@[Entity(repository_class: …)]` on the entity wins.
        def repository(entity_class : {{entity.id}}.class) : {{repository_class.id}}
          @repository_factory.repository(self, entity_class.as(AORM::Entity.class)).as {{repository_class.id}}
        end
      {% else %}
        # Default overload: returns a generic `EntityRepository(T)` typed to this entity.
        def repository(entity_class : {{entity.id}}.class) : AORM::EntityRepository({{entity.id}})
          @repository_factory.repository(self, entity_class.as(AORM::Entity.class)).as AORM::EntityRepository({{entity.id}})
        end
      {% end %}
    {% end %}
  end

  # :inherit:
  #
  # For every concrete entity, an overload returns its repository typed as `AORM::EntityRepository` of the entity, or as the entity's custom repository class.
  # This overload is used for a class only known as an `AORM::Entity.class`.
  def repository(entity_class : AORM::Entity.class) : AORM::RepositoryInterface
    @repository_factory.repository self, entity_class
  end

  # :inherit:
  def contains(entity : AORM::Entity) : Bool
    uow = self.unit_of_work
    entity = entity.as(AORM::Entity)

    uow.is_scheduled_for_insert?(entity) || uow.is_in_identity_map(entity) && !uow.is_scheduled_for_delete?(entity)
  end

  # :inherit:
  def begin_transaction : Nil
    @connection.begin_transaction
  end

  # :inherit:
  def commit : Nil
    @connection.commit
  end

  # :inherit:
  def rollback : Nil
    @connection.rollback
  end

  # Runs the block in a transaction, flushing before it commits, and returns the block's value.
  # If the block or the flush raises, the entity manager is closed and the transaction rolled back.
  #
  # ```
  # user = em.wrap_in_transaction do
  #   user = User.new
  #   user.name = "George"
  #
  #   em.persist user
  #
  #   user
  # end
  #
  # user.id # => 1
  # ```
  def wrap_in_transaction(& : self -> T) : T forall T
    @connection.begin_transaction

    successful = false

    begin
      result = yield self

      self.flush
      @connection.commit

      successful = true

      result
    ensure
      unless successful
        self.close
        @connection.rollback if @connection.transaction_active?
      end
    end
  end

  # :inherit:
  #
  # The connection, and any transaction open on it, are left to whoever provided the connection.
  def close : Nil
    self.clear

    @closed = true
  end

  # :nodoc:
  def hydrator(mode : HydrationMode) : AORM::Internal::Hydrators::Abstract
    case mode
    in .object?        then AORM::Internal::Hydrators::Object.new self
    in .simple_object? then AORM::Internal::Hydrators::SimpleObject.new self
    end
  end

  # Creates a query executing the native *sql*, whose results are hydrated as described by *rsm*.
  #
  # ```
  # rsm = AORM::Query::ResultSetMapping.new
  # rsm.add_entity_result User, "u"
  # rsm.add_field_result "u", "id", "id"
  # rsm.add_field_result "u", "name", "name"
  #
  # query = em.create_native_query "SELECT u.id, u.name FROM users u WHERE u.name LIKE ?", rsm
  # query.set_parameter 1, "G%"
  #
  # query.get_result # => [#<User:0x7f3a1c2b5e40 @id=1, @name="George">]
  # ```
  #
  # See `AORM::NativeQuery` for more information.
  def create_native_query(sql : String, rsm : Query::ResultSetMapping) : NativeQuery
    NativeQuery.new(self, sql, rsm)
  end

  private def unless_closed(&) : Nil
    # Use an actual Exception type for this
    raise "EM IS CLOSED" if @closed
    yield
  end
end
