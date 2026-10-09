require "./spec_helper"
require "uuid"

# Inline test entities — kept here rather than under spec/models/ because they only matter to this file's coverage of UnitOfWork edge cases.
@[AORMA::Entity]
class VersionedAssignedIdentifierEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  property! id : Int32
  # @[AORMA::Version] not implemented
  property version : Int32 = 0
end

@[AORMA::Entity]
class EntityWithStringIdentifier < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil
end

@[AORMA::Entity]
class EntityWithBooleanIdentifier < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Bool? = nil
end

@[AORMA::Entity]
class EntityWithCompositeStringIdentifier < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id1 : String? = nil
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id2 : String? = nil
end

@[AORMA::Entity]
class CascadePersistedEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  def initialize
    @id = "#{self.class.name}-#{UUID.random}"
  end
end

@[AORMA::Entity]
class EntityWithCascadingAssociation < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  @[AORMA::OneToOne(target_entity: CascadePersistedEntity, cascade: ["persist"])]
  @[AORMA::JoinColumn(name: "cascaded_id", referenced_column_id: "id")]
  property cascaded : CascadePersistedEntity? = nil

  def initialize
    @id = "#{self.class.name}-#{UUID.random}"
  end
end

@[AORMA::Entity]
class EntityWithNonCascadingAssociation < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  @[AORMA::OneToOne(target_entity: CascadePersistedEntity)]
  @[AORMA::JoinColumn(name: "non_cascaded_id", referenced_column_id: "id")]
  property non_cascaded : CascadePersistedEntity? = nil

  def initialize
    @id = "#{self.class.name}-#{UUID.random}"
  end
end

@[AORMA::Entity]
class TaggedItem < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column]
  property! name : String
end

@[AORMA::Entity]
class TagOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::ManyToMany(target_entity: TaggedItem, index_by: "name", cascade: ["persist"])]
  property tags : AORM::PersistentCollection(TaggedItem) = AORM::PersistentCollection(TaggedItem).new
end

@[AORMA::Entity]
class CustomJoinProduct < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32
end

@[AORMA::Entity]
class CustomJoinCategory < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::ManyToMany(target_entity: CustomJoinProduct, cascade: ["persist"])]
  @[AORMA::JoinTable(name: "my_custom_join_table")]
  property products : AORM::PersistentCollection(CustomJoinProduct) = AORM::PersistentCollection(CustomJoinProduct).new
end

# Test entity with fully custom join columns
@[AORMA::Entity]
class CustomColumnProduct < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32
end

@[AORMA::Entity]
class CustomColumnCategory < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::ManyToMany(target_entity: CustomColumnProduct, cascade: ["persist"])]
  @[AORMA::JoinTable(name: "category_product_map")]
  @[AORMA::JoinColumn(name: "cat_id", referenced_column_name: "id")]
  @[AORMA::InverseJoinColumn(name: "prod_id", referenced_column_name: "id")]
  property products : AORM::PersistentCollection(CustomColumnProduct) = AORM::PersistentCollection(CustomColumnProduct).new
end

# Fixtures: a User has many Posts (OneToMany inverse) backed by a Post that belongs to a User (ManyToOne owning).
# Used to exercise OneToMany lazy load, metadata, and cascade-persist.
# Fixtures: ToOne owning sides that explicitly override the join-column name
# via @[AORMA::JoinColumn], to verify the annotation flows through the driver
# rather than being silently dropped.
@[AORMA::Entity]
class CustomJoinTarget < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32
end

@[AORMA::Entity]
class CustomJoinOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::OneToOne]
  @[AORMA::JoinColumn(name: "explicit_one_to_one_fk", referenced_column_name: "id")]
  property linked : CustomJoinTarget? = nil

  @[AORMA::ManyToOne]
  @[AORMA::JoinColumn(name: "explicit_many_to_one_fk", referenced_column_name: "id")]
  property parent : CustomJoinTarget? = nil
end

# OneToOne owning/inverse pair, used to drive `UnitOfWork#resolve_pending_to_one_associations` through its inverse-side branch (target_id nil → persister.load_one_to_one_entity).
@[AORMA::Entity]
@[AORMA::Table(name: "inv_o2o_owners")]
class InverseO2OOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::OneToOne(inversed_by: "owner")]
  @[AORMA::JoinColumn(name: "target_id", referenced_column_id: "id")]
  property target : InverseO2OTarget? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "inv_o2o_targets")]
class InverseO2OTarget < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::OneToOne(mapped_by: "target")]
  property owner : InverseO2OOwner? = nil
end

# CmsUser variant whose `groups` association is configured with cascade: ["remove"], used to drive the cascade-remove walk in `UnitOfWork#cascade_remove`.
@[AORMA::Entity]
@[AORMA::Table(name: "cascade_users")]
class CascadeRemoveUser < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column]
  property! username : String

  @[AORMA::ManyToMany(target_entity: CmsGroup, cascade: ["remove"])]
  property groups : AORM::Collection(CmsGroup) = AORM::ArrayCollection(CmsGroup).new
end

# Cascade-detach pair: walking `parent` from the owner detaches the target alongside it.
@[AORMA::Entity]
@[AORMA::Table(name: "detach_owners")]
class DetachOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::OneToOne(target_entity: DetachTarget, cascade: ["detach"])]
  @[AORMA::JoinColumn(name: "target_id", referenced_column_id: "id")]
  property target : DetachTarget? = nil
end

@[AORMA::Entity]
@[AORMA::Table(name: "detach_targets")]
class DetachTarget < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32
end

@[AORMA::Entity]
@[AORMA::Table(name: "blog_users")]
class BlogUser < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column]
  property! username : String

  @[AORMA::OneToMany(mapped_by: "user", cascade: ["persist"])]
  property posts : AORM::Collection(BlogPost) = AORM::ArrayCollection(BlogPost).new
end

@[AORMA::Entity]
@[AORMA::Table(name: "blog_posts")]
class BlogPost < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::Column]
  property! title : String

  @[AORMA::ManyToOne(inversed_by: "posts")]
  property user : BlogUser? = nil
end

# Stand-in persister that mimics the hydrator's `:collection`-hint behavior:
# when `load_many_to_many_collection` runs, the canned entities are pushed
# directly into the target collection via `hydrate_add`. Used to verify that
# the UoW doesn't add them a second time on top of that.
class CollectionAddingPersister < AORM::Persisters::Entity::Basic
  property canned_entities : Array(AORM::Entity) = [] of AORM::Entity
  getter? load_many_to_many_called : Bool = false

  def load_many_to_many_collection(
    assoc : AORM::Mapping::ManyToMany,
    source_entity : AORM::Entity,
    collection : AORM::PersistentCollection,
  ) : Array
    @load_many_to_many_called = true
    @canned_entities.each { |e| collection.hydrate_add e }
    @canned_entities
  end
end

# Pair of entities whose class names sort in the opposite order to how the specs register them.
@[AORMA::Entity]
class UpdateOrderAlpha < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! name : String
end

@[AORMA::Entity]
class UpdateOrderBeta < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property! id : Int32

  @[AORMA::Column]
  property! name : String
end

# Insert cycle where only one edge may be broken: `head.tail` is nullable while `tail.head` is NOT NULL.
@[AORMA::Entity]
class NullableCycleHead < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::OneToOne]
  property tail : NullableCycleTail? = nil
end

@[AORMA::Entity]
class NullableCycleTail < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  @[AORMA::ManyToOne]
  @[AORMA::JoinColumn(nullable: false)]
  property head : NullableCycleHead? = nil
end

# Records `update` calls into a log shared across persisters so the cross-class execution order can be asserted.
class UpdateLoggingPersister < AORM::Persisters::Entity::Basic
  def initialize(em : AORM::EntityManagerInterface, class_metadata : AORM::Mapping::ClassInterface, @log : Array(AORM::Entity))
    super em, class_metadata
  end

  def update(entity : AORM::Entity) : Nil
    @log << entity
  end
end

# Captures `load_one_to_one_entity` calls so the inverse-side resolution path can be asserted without standing up a real persister.
class CapturingOneToOnePersister < AORM::Persisters::Entity::Basic
  setter mock_load_one_to_one_result : AORM::Entity? = nil
  record OneToOneCall, assoc : AORM::Mapping::ToOneInverseSide, source : AORM::Entity
  getter one_to_one_calls : Array(OneToOneCall) = [] of OneToOneCall

  def load_one_to_one_entity(
    assoc : AORM::Mapping::ToOneInverseSide,
    source_entity : AORM::Entity,
  ) : AORM::Entity?
    @one_to_one_calls << OneToOneCall.new(assoc, source_entity)
    @mock_load_one_to_one_result
  end
end

# Fixtures: associations declared without `target_entity` so the inference
# from the property's type restriction is what gets exercised.
@[AORMA::Entity]
class InferredTargetTag < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32
end

@[AORMA::Entity]
class InferredTargetOwner < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue]
  property! id : Int32

  # Inferred from `InferredTargetTag?`
  @[AORMA::OneToOne]
  property primary : InferredTargetTag? = nil

  # Inferred from `AORM::Collection(InferredTargetTag)`
  @[AORMA::ManyToMany]
  property tags : AORM::Collection(InferredTargetTag) = AORM::ArrayCollection(InferredTargetTag).new
end

@[AORMA::Entity]
class UnmappedPropertyEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::Column]
  property name : String = ""

  # Not mapped to a column.
  property? greeted : Bool = false
end

struct UnitOfWorkTest < ASPEC::TestCase
  @connection : MockConnection
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @connection = MockConnection.new
    @connection.push_ids 1, 2, 3, 4, 5, 6
    @em = MockEntityManager.new @connection
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  def test_register_removed_on_new_entity_is_ignored : Nil
    user = ForumUser.new
    user.username = "Fred"
    @uow.is_scheduled_for_delete?(user).should be_false
    @uow.schedule_for_delete user
    @uow.is_scheduled_for_delete?(user).should be_false
  end

  def test_saving_single_entity_with_identity_column_forces_insert : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    user = ForumUser.new
    user.username = "Fred"
    @uow.persist user

    user_persister.inserts.size.should eq 0
    user_persister.updates.size.should eq 0
    user_persister.deletes.size.should eq 0
    @uow.is_in_identity_map(user).should be_false
    @uow.is_scheduled_for_insert?(user).should be_true

    user_persister.reset

    @uow.commit
    user_persister.inserts.size.should eq 1
    user_persister.updates.size.should eq 0
    user_persister.deletes.size.should eq 0

    user.id.should be_a Int32
  end

  def test_multiple_inserts_are_batched_in_the_persister : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata Country
    @uow.set_entity_persister Country, user_persister

    country1 = Country.new
    country1.country = "Italy"
    country2 = Country.new
    country2.country = "Germany"

    @uow.persist country1
    @uow.persist country2
    @uow.commit

    user_persister.inserts.size.should eq 2
    user_persister.execute_insert_call_count.should eq 1
  end

  def test_cascaded_identity_column_insert : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumAvatar, avatar_persister
    avatar_persister.mock_id_generator = :identity

    user = ForumUser.new
    user.username = "Fred"
    avatar = ForumAvatar.new
    user.avatar = avatar
    @uow.persist user
    @uow.commit

    user.id.is_a? Number
    avatar.id.is_a? Number

    user_persister.inserts.size.should eq 1
    user_persister.updates.size.should eq 0
    user_persister.deletes.size.should eq 0

    avatar_persister.inserts.size.should eq 1
    avatar_persister.updates.size.should eq 0
    avatar_persister.deletes.size.should eq 0
  end

  def test_load_collection_does_not_double_add_hydrated_entities : Nil
    # The persister's `load_many_to_many_collection` already adds the loaded
    # entities into the target collection (via the `:collection` hydrator hint).
    # `UnitOfWork#load_collection` must not re-add them on top of that, or the
    # collection ends up with each row twice.
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister

    group_persister = CollectionAddingPersister.new @em, @em.class_metadata(CmsGroup)
    @uow.set_entity_persister CmsGroup, group_persister
    group_persister.canned_entities = [build_cms_group(1, "admins"), build_cms_group(2, "devs")] of AORM::Entity

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(7)
    data["username"] = AORM::Mapping::SingleValue.new("fred")
    user = @uow.create_entity(CmsUser, data).as CmsUser
    pc = user.groups.as(AORM::PersistentCollection(CmsGroup))

    @uow.load_collection pc

    pc.size.should eq 2
    pc.loaded?.should be_true
  end

  private def build_cms_group(id : Int32, name : String) : CmsGroup
    g = CmsGroup.new
    g.name = name
    pointerof(g.@id).value = id
    g
  end

  def test_compute_change_set_does_not_initialize_unchanged_lazy_collection : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister

    # Drive the hydration path so the user gets an injected (uninitialized)
    # PersistentCollection for `groups`, the same as a real `find!` would.
    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(1)
    data["username"] = AORM::Mapping::SingleValue.new("fred")
    user = @uow.create_entity(CmsUser, data).as CmsUser
    pc = user.groups.as(AORM::PersistentCollection(CmsGroup))
    pc.loaded?.should be_false

    # Modify a scalar field and commit. The lazy groups collection must NOT be
    # initialized as a side effect of computing the user's changeset.
    user.username = "fred-renamed"
    @uow.commit

    pc.loaded?.should be_false
  end

  def test_schedule_extra_update_merges_repeated_changesets : Nil
    user = ForumUser.new
    user.username = "fred"

    avatar1 = ForumAvatar.new
    avatar2 = ForumAvatar.new
    val1 = AORM::Mapping::SingleValue.new(avatar1)
    val2 = AORM::Mapping::SingleValue.new(avatar2)

    @uow.schedule_extra_update user, {"avatar" => AORM::UnitOfWork::Change.new(nil, val1)}
    @uow.schedule_extra_update user, {"username" => AORM::UnitOfWork::Change.new(nil, val2)}

    extras = @uow.extra_update_for user
    extras.keys.sort.should eq ["avatar", "username"]
  end

  def test_execute_extra_updates_runs_persister_update_with_patched_changeset : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ForumAvatar
    @uow.set_entity_persister ForumAvatar, avatar_persister
    avatar_persister.mock_id_generator = :identity

    avatar = ForumAvatar.new
    user = ForumUser.new
    user.username = "fred"
    user.avatar = avatar

    # The cycle-style write would normally be wired via a persister, but here we
    # poke the UoW directly to verify the update fires after the main inserts.
    @uow.persist user
    avatar_value = AORM::Mapping::SingleValue.new(avatar)
    @uow.schedule_extra_update user, {"avatar" => AORM::UnitOfWork::Change.new(nil, avatar_value)}

    @uow.commit

    user_persister.updates.size.should eq 1
    user_persister.updates.first.should be user
    @uow.extra_update_for(user).should be_empty
  end

  # Concurrent flushes touching the same rows must acquire row locks in the same order to avoid deadlocks.
  def test_commit_executes_updates_ordered_by_class_name : Nil
    log = [] of AORM::Entity
    @uow.set_entity_persister UpdateOrderBeta, UpdateLoggingPersister.new(@em, @em.class_metadata(UpdateOrderBeta), log)
    @uow.set_entity_persister UpdateOrderAlpha, UpdateLoggingPersister.new(@em, @em.class_metadata(UpdateOrderAlpha), log)

    beta = UpdateOrderBeta.new
    beta.id = 1
    beta.name = "before"
    @uow.register_managed beta, {"id" => 1}, {"id" => 1, "name" => "before"}

    alpha = UpdateOrderAlpha.new
    alpha.id = 1
    alpha.name = "before"
    @uow.register_managed alpha, {"id" => 1}, {"id" => 1, "name" => "before"}

    beta.name = "after"
    alpha.name = "after"

    @uow.commit

    log.map(&.class).should eq [UpdateOrderAlpha, UpdateOrderBeta]
  end

  # Within a single class, UPDATEs are ordered by identifier hash rather than by when the entities were loaded.
  def test_commit_executes_updates_ordered_by_identifier_within_a_class : Nil
    log = [] of AORM::Entity
    @uow.set_entity_persister UpdateOrderAlpha, UpdateLoggingPersister.new(@em, @em.class_metadata(UpdateOrderAlpha), log)

    {2, 1, 3}.each do |id|
      entity = UpdateOrderAlpha.new
      entity.id = id
      entity.name = "before"
      @uow.register_managed entity, {"id" => id}, {"id" => id, "name" => "before"}
      entity.name = "after"
    end

    @uow.commit

    log.map(&.as(UpdateOrderAlpha).id).should eq [1, 2, 3]
  end

  # `clear` discards all pending work, so nothing computed or scheduled beforehand may reach the database on the next commit.
  def test_clear_discards_pending_updates_change_sets_and_orphan_removals : Nil
    log = [] of AORM::Entity
    @uow.set_entity_persister UpdateOrderAlpha, UpdateLoggingPersister.new(@em, @em.class_metadata(UpdateOrderAlpha), log)

    entity = UpdateOrderAlpha.new
    entity.id = 1
    entity.name = "before"
    @uow.register_managed entity, {"id" => 1}, {"id" => 1, "name" => "before"}
    entity.name = "after"
    @uow.compute_changesets

    orphan = UpdateOrderAlpha.new
    orphan.id = 2
    orphan.name = "orphan"
    @uow.register_managed orphan, {"id" => 2}, {"id" => 2, "name" => "orphan"}
    @uow.schedule_orphan_removal orphan

    @uow.clear

    @uow.scheduled_entity_updates.should be_empty
    @uow.entity_changeset(entity).should be_empty

    @uow.commit

    log.should be_empty
  end

  # A NOT NULL foreign key cannot be deferred to an extra update, so the cycle must be broken on the nullable edge.
  def test_insert_execution_order_breaks_cycles_on_nullable_join_columns_only : Nil
    head = NullableCycleHead.new
    tail = NullableCycleTail.new
    head.tail = tail
    tail.head = head

    @uow.persist head
    @uow.persist tail
    @uow.compute_changesets

    order = @uow.insert_execution_order

    order.index!(head).should be < order.index!(tail)
  end

  def test_insert_execution_order_places_to_one_owning_side_target_first : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ForumAvatar
    @uow.set_entity_persister ForumAvatar, avatar_persister
    avatar_persister.mock_id_generator = :identity

    user = ForumUser.new
    user.username = "Fred"
    avatar = ForumAvatar.new
    user.avatar = avatar

    # Persisting the user cascades into the avatar; the user gets registered
    # for insert first, but the FK on users -> avatars means the topological
    # sort must place the avatar ahead of the user in the execution order.
    @uow.persist user
    @uow.compute_changesets

    order = @uow.insert_execution_order

    order.index(avatar).should_not be_nil
    order.index(user).should_not be_nil
    order.index(avatar).not_nil!.should be < order.index(user).not_nil!
  end

  @[Pending]
  def test_get_entity_state_on_versioned_entity_with_assigned_identifier : Nil
    # Requires: @[AORMA::Version] annotation support
  end

  def test_get_entity_state_with_assigned_identity : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, persister

    ph = CmsPhonenumber.new
    ph.phonenumber = "12345"

    @uow.entity_state(ph).should eq AORM::UnitOfWork::EntityState::New
    persister.exists_called?.should be_true

    persister.reset

    # exists check should be skipped if entity is already managed
    @uow.register_managed ph, {"phonenumber" => "12345"}, {} of String => NoReturn
    @uow.entity_state(ph).should eq AORM::UnitOfWork::EntityState::Managed
    persister.exists_called?.should be_false

    ph2 = CmsPhonenumber.new
    ph2.phonenumber = "12345"
    @uow.entity_state(ph2).should eq AORM::UnitOfWork::EntityState::Detached
    persister.exists_called?.should be_false
  end

  # An identifier generated on insert means the entity was inserted already, so an untracked entity that has one is detached.
  def test_get_entity_state_with_generated_identifier_is_detached : Nil
    user = ForumUser.new
    pointerof(user.@id).value = 1

    @uow.entity_state(user).should eq AORM::UnitOfWork::EntityState::Detached
  end

  # Only mapped fields are tracked, so other instance variables are never part of a change set.
  def test_change_set_of_a_new_entity_excludes_unmapped_instance_variables : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata UnmappedPropertyEntity
    @uow.set_entity_persister UnmappedPropertyEntity, persister

    entity = UnmappedPropertyEntity.new
    entity.id = 1
    entity.name = "George"
    entity.greeted = true

    @uow.persist entity
    @uow.compute_changesets

    @uow.entity_changeset(entity).keys.should eq ["id", "name"]
  end

  def test_recomputed_change_set_excludes_unmapped_instance_variables : Nil
    entity = UnmappedPropertyEntity.new
    entity.id = 1
    entity.name = "George"
    @uow.register_managed entity, {"id" => 1}, {"id" => 1, "name" => "George"}

    entity.name = "Jim"
    entity.greeted = true
    @uow.recompute_single_entity_change_set @em.class_metadata(UnmappedPropertyEntity), entity

    @uow.entity_changeset(entity).keys.should eq ["name"]
  end

  def test_no_undefined_index_notice_on_schedule_for_update_without_changes : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    user = ForumUser.new
    user.username = "Fred"
    @uow.persist user
    @uow.commit

    # Schedule for update without changes
    @uow.schedule_for_update user
    @uow.scheduled_entity_updates.should_not be_empty
    @uow.commit
    @uow.scheduled_entity_updates.should be_empty
  end

  def test_removed_and_re_persisted_entities_are_in_the_identity_map : Nil
    phonenumber_persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, phonenumber_persister

    phone = CmsPhonenumber.new
    phone.phonenumber = "123456"

    @uow.persist phone
    @uow.commit

    @uow.is_in_identity_map(phone).should be_true

    @uow.schedule_for_delete phone
    @uow.is_in_identity_map(phone).should be_false

    @uow.persist phone
    @uow.is_in_identity_map(phone).should be_true
  end

  @[DataProvider("entities_with_valid_identifiers_provider")]
  def test_add_to_identity_map_valid_identifiers(entity : AORM::Entity, id_hash : String) : Nil
    @uow.persist entity
    @uow.add_to_identity_map entity

    @uow.get_by_id_hash(id_hash, entity.class).should be entity
  end

  def entities_with_valid_identifiers_provider : Hash
    empty_string = EntityWithStringIdentifier.new
    empty_string.id = ""

    non_empty_string = EntityWithStringIdentifier.new
    non_empty_string.id = "test-id-123"

    bool_true = EntityWithBooleanIdentifier.new
    bool_true.id = true

    bool_false = EntityWithBooleanIdentifier.new
    bool_false.id = false

    {
      "empty string, single field"     => {empty_string, ""},
      "non-empty string, single field" => {non_empty_string, "test-id-123"},
      # # two fields
      "boolean true"  => {bool_true, "1"},
      "boolean false" => {bool_false, ""},
    }
  end

  def test_registering_a_managed_instance_requires_a_non_empty_identifier : Nil
    entity = EntityWithStringIdentifier.new
    entity.id = nil

    expect_raises(Exception, "entity without identity") do
      @uow.register_managed entity, {} of String => AORM::Mapping::Value, {} of String => AORM::Mapping::Value
    end
  end

  @[DataProvider("entities_with_invalid_identifiers_provider")]
  def test_add_to_identity_map_invalid_identifiers(entity : AORM::Entity, id : Hash(String, AORM::Mapping::Value)) : Nil
    expect_raises(Exception) do
      @uow.register_managed entity, id, {} of String => AORM::Mapping::Value
    end
  end

  def entities_with_invalid_identifiers_provider : Hash
    {
      "nil string" => {
        EntityWithStringIdentifier.new,
        {"id" => AORM::Mapping::ColumnValue.new("id", nil).as(AORM::Mapping::Value)},
      },
      "composite, both nil" => {
        EntityWithCompositeStringIdentifier.new,
        {
          "id1" => AORM::Mapping::ColumnValue.new("id1", nil).as(AORM::Mapping::Value),
          "id2" => AORM::Mapping::ColumnValue.new("id2", nil).as(AORM::Mapping::Value),
        },
      },
      "composite, first field nil" => {
        EntityWithCompositeStringIdentifier.new,
        {
          "id1" => AORM::Mapping::ColumnValue.new("id1", nil).as(AORM::Mapping::Value),
          "id2" => AORM::Mapping::ColumnValue.new("id2", "bar").as(AORM::Mapping::Value),
        },
      },
      "composite, second field nil" => {
        EntityWithCompositeStringIdentifier.new,
        {
          "id1" => AORM::Mapping::ColumnValue.new("id1", "foo").as(AORM::Mapping::Value),
          "id2" => AORM::Mapping::ColumnValue.new("id2", nil).as(AORM::Mapping::Value),
        },
      },
    }
  end

  def test_new_associated_entity_persistence_through_cascaded_associations_first : Nil
    persister1 = MockEntityPersister.new @em, @em.class_metadata CascadePersistedEntity
    persister2 = MockEntityPersister.new @em, @em.class_metadata EntityWithCascadingAssociation
    persister3 = MockEntityPersister.new @em, @em.class_metadata EntityWithNonCascadingAssociation
    @uow.set_entity_persister CascadePersistedEntity, persister1
    @uow.set_entity_persister EntityWithCascadingAssociation, persister2
    @uow.set_entity_persister EntityWithNonCascadingAssociation, persister3

    cascade_persisted = CascadePersistedEntity.new
    cascading = EntityWithCascadingAssociation.new
    non_cascading = EntityWithNonCascadingAssociation.new

    # Both entities reference the same CascadePersistedEntity.
    # EntityWithCascadingAssociation has cascade: ["persist"], so persisting it
    # will also persist CascadePersistedEntity. EntityWithNonCascadingAssociation
    # does not have cascade, but since CascadePersistedEntity gets persisted
    # through the other path, no error should occur.
    cascading.cascaded = cascade_persisted
    non_cascading.non_cascaded = cascade_persisted

    @uow.persist cascading
    @uow.persist non_cascading

    @uow.commit

    persister1.inserts.size.should eq 1
    persister2.inserts.size.should eq 1
    persister3.inserts.size.should eq 1
  end

  def test_new_associated_entity_persistence_through_non_cascaded_associations_first : Nil
    persister1 = MockEntityPersister.new @em, @em.class_metadata CascadePersistedEntity
    persister2 = MockEntityPersister.new @em, @em.class_metadata EntityWithCascadingAssociation
    persister3 = MockEntityPersister.new @em, @em.class_metadata EntityWithNonCascadingAssociation
    @uow.set_entity_persister CascadePersistedEntity, persister1
    @uow.set_entity_persister EntityWithCascadingAssociation, persister2
    @uow.set_entity_persister EntityWithNonCascadingAssociation, persister3

    cascade_persisted = CascadePersistedEntity.new
    cascading = EntityWithCascadingAssociation.new
    non_cascading = EntityWithNonCascadingAssociation.new

    # First persist and flush EntityWithCascadingAssociation with the cascading
    # association not set. Having the "cascading path" involve a non-new object
    # is important to show that the ORM should be considering cascades across
    # entity changesets in subsequent flushes.
    cascading.cascaded = nil

    @uow.persist cascading
    @uow.commit

    persister1.inserts.size.should eq 0
    persister2.inserts.size.should eq 1
    persister3.inserts.size.should eq 0

    # Note that we have NOT directly persisted the CascadePersistedEntity,
    # and EntityWithNonCascadingAssociation does NOT have a configured
    # cascade-persist.
    non_cascading.non_cascaded = cascade_persisted

    # However, EntityWithCascadingAssociation *does* have a cascade-persist
    # association, which ought to allow us to save the CascadePersistedEntity
    # anyway through that connection.
    cascading.cascaded = cascade_persisted

    @uow.persist non_cascading
    @uow.commit

    persister1.inserts.size.should eq 1
    persister2.inserts.size.should eq 1
    persister3.inserts.size.should eq 1
  end

  def test_previous_detected_illegal_new_non_cascaded_entities_are_cleaned_up : Nil
    persister1 = MockEntityPersister.new @em, @em.class_metadata CascadePersistedEntity
    persister2 = MockEntityPersister.new @em, @em.class_metadata EntityWithNonCascadingAssociation
    @uow.set_entity_persister CascadePersistedEntity, persister1
    @uow.set_entity_persister EntityWithNonCascadingAssociation, persister2

    cascade_persisted = CascadePersistedEntity.new
    non_cascading = EntityWithNonCascadingAssociation.new

    # We explicitly cause the ORM to detect a non-persisted new entity in the
    # association graph (non_cascaded has no cascade: ["persist"])
    non_cascading.non_cascaded = cascade_persisted

    @uow.persist non_cascading

    expect_raises(Exception, "new entities found through relationships") do
      @uow.commit
    end

    persister1.inserts.should be_empty
    persister2.inserts.should be_empty

    @uow.clear
    @uow.persist CascadePersistedEntity.new
    @uow.commit

    # Persistence operations should just recover normally
    persister1.inserts.size.should eq 1
    persister2.inserts.size.should eq 0
  end

  @[Pending]
  def test_commit_throw_optimistic_lock_exception_when_connection_commit_fails : Nil
    # Requires: OptimisticLockException
  end

  def test_it_throws_when_looking_up_identifier_for_unknown_entity : Nil
    # Use an entity that hasn't been tracked by the UnitOfWork
    unknown_entity = EntityWithStringIdentifier.new
    unknown_entity.id = "test"

    expect_raises(Exception, /Unable to find.*entity identifier associated with the UnitOfWork/) do
      @uow.entity_identifier unknown_entity
    end
  end

  def test_removed_entity_is_removed_from_many_to_many_collection : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister
    user_persister.mock_id_generator = :identity

    group_persister = MockEntityPersister.new @em, @em.class_metadata CmsGroup
    @uow.set_entity_persister CmsGroup, group_persister
    group_persister.mock_id_generator = :identity

    user = CmsUser.new
    user.username = "test_user"

    group1 = CmsGroup.new
    group1.name = "group1"

    group2 = CmsGroup.new
    group2.name = "group2"

    user.groups << group1
    user.groups << group2

    @uow.persist user
    @uow.commit

    user_persister.inserts.size.should eq 1
    group_persister.inserts.size.should eq 2

    user.id.should_not be_nil
    group1.id.should_not be_nil
    group2.id.should_not be_nil

    # Take a snapshot of the collection state after persist.
    # The UoW promotes user.groups to a PersistentCollection during commit,
    # so the runtime type matches even though the property is declared as Collection.
    user.groups.as(AORM::PersistentCollection(CmsGroup)).take_snapshot

    # Verify both groups are in the collection
    user.groups.size.should eq 2
    user.groups.includes?(group1).should be_true
    user.groups.includes?(group2).should be_true

    # The UoW defers the in-memory collection cleanup until after `commit`
    # succeeds, so the assertion has to come after the next flush.
    @uow.remove group1
    @uow.commit

    user.groups.includes?(group1).should be_false
    user.groups.size.should eq 1
    user.groups.includes?(group2).should be_true
  end

  def test_removed_entity_is_removed_from_one_to_many_collection : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata BlogUser
    @uow.set_entity_persister BlogUser, user_persister
    user_persister.mock_id_generator = :identity

    post_persister = MockEntityPersister.new @em, @em.class_metadata BlogPost
    @uow.set_entity_persister BlogPost, post_persister
    post_persister.mock_id_generator = :identity

    user = BlogUser.new
    user.username = "fred"
    p1 = BlogPost.new
    p1.title = "first"
    p2 = BlogPost.new
    p2.title = "second"
    user.posts << p1
    user.posts << p2

    @uow.persist user
    @uow.commit

    # Now remove p1 and re-flush — it should be marked for delete AND dropped
    # from user.posts (via pending_collection_element_removals applied on commit).
    @uow.remove p1
    @uow.commit

    user.posts.size.should eq 1
    user.posts.includes?(p2).should be_true
    user.posts.includes?(p1).should be_false
  end

  def test_it_throws_when_application_provided_ids_collide : Nil
    entity1 = EntityWithStringIdentifier.new
    entity1.id = "same-id"

    entity2 = EntityWithStringIdentifier.new
    entity2.id = "same-id"

    @uow.persist entity1
    # For entities with assigned IDs, persist automatically adds to identity map

    # Persisting entity2 with same ID should throw collision error
    expect_raises(Exception, "entity identity collision") do
      @uow.persist entity2
    end
  end

  def test_it_preserves_the_original_exception_on_rollback_failure : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, user_persister
    user_persister.mock_id_generator = :identity

    user = ForumUser.new
    user.username = "Fred"
    @uow.persist user

    # Mock an exception during insert by using a persister that throws
    failing_persister = FailingEntityPersister.new @em, @em.class_metadata(ForumUser), "Insert failed"
    @uow.set_entity_persister ForumUser, failing_persister

    expect_raises(Exception, "Insert failed") do
      @uow.commit
    end
  end

  def test_refresh_updates_managed_entity_from_persister : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, persister

    user = ForumUser.new
    user.username = "fred-original"
    pointerof(user.@id).value = 7
    @uow.register_managed user, {"id" => 7}, {"id" => 7, "username" => "fred-original"}

    # In-memory drift away from the DB row.
    user.username = "fred-stale-edit"

    fresh_data = Hash(String, DB::Any).new
    fresh_data["id"] = 7
    fresh_data["username"] = "fred-from-db"
    persister.mock_refresh_data = fresh_data

    @uow.refresh user

    user.username.should eq "fred-from-db"
    user.id.should eq 7
  end

  # A fresh row carries foreign key columns alongside the fields; they aren't fields and must not be stored as such.
  def test_refresh_ignores_foreign_key_columns_in_the_fresh_row : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, persister

    user = ForumUser.new
    user.username = "fred-original"
    pointerof(user.@id).value = 7
    @uow.register_managed user, {"id" => 7}, {"id" => 7, "username" => "fred-original"}

    persister.mock_refresh_data = {"id" => 7, "username" => "fred-from-db", "avatar_id" => 99} of String => DB::Any

    @uow.refresh user

    user.username.should eq "fred-from-db"
  end

  def test_refresh_writes_false_and_nil_values_back : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata RefreshableFlags
    @uow.set_entity_persister RefreshableFlags, persister

    entity = RefreshableFlags.new
    entity.id = 7
    entity.note = "stale"
    @uow.register_managed entity, {"id" => 7}, {"id" => 7, "active" => true, "note" => "stale"}

    persister.mock_refresh_data = {"id" => 7, "active" => false, "note" => nil} of String => DB::Any

    @uow.refresh entity

    entity.active?.should be_false
    entity.note.should be_nil

    # The fresh row is the new baseline, so nothing is pending afterwards.
    @uow.compute_changesets
    @uow.entity_changeset(entity).should be_empty
  end

  def test_refresh_raises_for_new_entity : Nil
    user = ForumUser.new
    user.username = "fred-new"

    # Never registered as managed.
    expect_raises(Exception, /not managed/) do
      @uow.refresh user
    end
  end

  def test_refresh_raises_for_removed_entity : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata ForumUser
    @uow.set_entity_persister ForumUser, persister

    user = ForumUser.new
    user.username = "fred-removed"
    pointerof(user.@id).value = 9
    @uow.register_managed user, {"id" => 9}, {"id" => 9, "username" => "fred-removed"}
    @uow.schedule_for_delete user

    expect_raises(Exception, /not managed/) do
      @uow.refresh user
    end
  end

  def test_explicit_join_column_on_one_to_one_owning_side_overrides_default : Nil
    cm = @em.class_metadata CustomJoinOwner

    assoc = cm.association_mappings["linked"].not_nil!
    owning = assoc.as AORM::Mapping::OneToOneOwningSide
    owning.join_columns.size.should eq 1
    owning.join_columns.first.name.should eq "explicit_one_to_one_fk"
  end

  def test_explicit_join_column_on_many_to_one_owning_side_overrides_default : Nil
    cm = @em.class_metadata CustomJoinOwner

    assoc = cm.association_mappings["parent"].not_nil!
    owning = assoc.as AORM::Mapping::ManyToOneOwningSide
    owning.join_columns.size.should eq 1
    owning.join_columns.first.name.should eq "explicit_many_to_one_fk"
  end

  def test_one_to_many_inverse_side_metadata_uses_mapped_by : Nil
    cm = @em.class_metadata BlogUser

    assoc = cm.association_mappings["posts"].not_nil!
    assoc.should be_a AORM::Mapping::OneToManyInverseSide
    assoc.target_entity.should eq BlogPost
    assoc.as(AORM::Mapping::OneToManyInverseSide).mapped_by.should eq "user"
  end

  def test_many_to_one_owning_side_metadata_carries_join_column : Nil
    cm = @em.class_metadata BlogPost

    assoc = cm.association_mappings["user"].not_nil!
    assoc.should be_a AORM::Mapping::ManyToOneOwningSide
    assoc.target_entity.should eq BlogUser

    owning = assoc.as AORM::Mapping::ManyToOneOwningSide
    owning.source_to_target_key_columns.should eq({"user_id" => "id"})
  end

  def test_one_to_many_required_mapped_by : Nil
    # Direct construction without `mapped_by` should fail loudly — OneToMany
    # is always the inverse side, so the `mapped_by` pointer is mandatory.
    expect_raises(Exception, /mapped_by/) do
      AORM::Mapping::OneToManyInverseSide.new(
        AORM::Mapping::Driver::ColumnMapping.new(
          field_name: "x",
          source_entity: BlogUser,
          target_entity: BlogPost,
        )
      )
    end
  end

  def test_one_to_many_cascade_persist_writes_target_inserts : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata BlogUser
    @uow.set_entity_persister BlogUser, user_persister
    user_persister.mock_id_generator = :identity

    post_persister = MockEntityPersister.new @em, @em.class_metadata BlogPost
    @uow.set_entity_persister BlogPost, post_persister
    post_persister.mock_id_generator = :identity

    user = BlogUser.new
    user.username = "fred"
    p1 = BlogPost.new
    p1.title = "first"
    p2 = BlogPost.new
    p2.title = "second"
    user.posts << p1
    user.posts << p2

    @uow.persist user
    @uow.commit

    user.id.should be > 0
    user_persister.inserts.size.should eq 1
    # Both posts cascade-persisted off of `user.posts`.
    post_persister.inserts.size.should eq 2
  end

  def test_target_entity_inferred_from_to_one_property_type : Nil
    cm = @em.class_metadata InferredTargetOwner

    assoc = cm.association_mappings["primary"].not_nil!
    assoc.target_entity.should eq InferredTargetTag
  end

  def test_target_entity_inferred_from_collection_element_type : Nil
    cm = @em.class_metadata InferredTargetOwner

    assoc = cm.association_mappings["tags"].not_nil!
    assoc.target_entity.should eq InferredTargetTag
  end

  def test_index_by_annotation_reaches_mapping : Nil
    class_metadata = @em.class_metadata TagOwner

    assoc = class_metadata.association_mappings["tags"]?
    assoc.should_not be_nil
    assoc = assoc.not_nil!

    assoc.should be_a AORM::Mapping::ManyToManyOwningSide
    if assoc.is_a?(AORM::Mapping::ManyToManyOwningSide)
      assoc.index_by.should eq "name"
    end
  end

  def test_custom_join_table_annotation : Nil
    class_metadata = @em.class_metadata CustomJoinCategory

    assoc = class_metadata.association_mappings["products"]?
    assoc.should_not be_nil
    assoc = assoc.not_nil!

    assoc.should be_a AORM::Mapping::ManyToManyOwningSide
    if assoc.is_a?(AORM::Mapping::ManyToManyOwningSide)
      join_table = assoc.join_table
      join_table.should_not be_nil
      join_table.not_nil!.name.should eq "my_custom_join_table"
    end
  end

  def test_custom_join_column_annotations : Nil
    class_metadata = @em.class_metadata CustomColumnCategory

    assoc = class_metadata.association_mappings["products"]?
    assoc.should_not be_nil
    assoc = assoc.not_nil!

    assoc.should be_a AORM::Mapping::ManyToManyOwningSide
    if assoc.is_a?(AORM::Mapping::ManyToManyOwningSide)
      join_table = assoc.join_table
      join_table.should_not be_nil
      jt = join_table.not_nil!

      jt.name.should eq "category_product_map"

      # Check join columns (source entity to join table)
      jt.join_columns.size.should eq 1
      jt.join_columns[0].name.should eq "cat_id"
      jt.join_columns[0].referenced_column_name.should eq "id"

      # Check inverse join columns (join table to target entity)
      jt.inverse_join_columns.size.should eq 1
      jt.inverse_join_columns[0].name.should eq "prod_id"
      jt.inverse_join_columns[0].referenced_column_name.should eq "id"
    end
  end

  def test_bidirectional_association_sync_on_add : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister
    user_persister.mock_id_generator = :identity

    group_persister = MockEntityPersister.new @em, @em.class_metadata CmsGroup
    @uow.set_entity_persister CmsGroup, group_persister
    group_persister.mock_id_generator = :identity

    user = CmsUser.new
    user.username = "test_user"

    group = CmsGroup.new
    group.name = "group1"

    # Owning-side helper updates both ends
    user.add_group group

    @uow.persist user
    @uow.commit

    group.users.includes?(user).should be_true
  end

  def test_schedule_for_delete_drops_an_insert_pending_entity : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, persister

    phone = CmsPhonenumber.new
    phone.phonenumber = "555"

    @uow.persist phone
    @uow.is_scheduled_for_insert?(phone).should be_true

    @uow.schedule_for_delete phone

    # An entity scheduled for insertion that gets removed before flush should
    # disappear entirely, not be queued for deletion of a row that was never
    # inserted.
    @uow.is_scheduled_for_insert?(phone).should be_false
    @uow.is_scheduled_for_delete?(phone).should be_false
  end

  def test_schedule_for_update_raises_on_entity_without_identity : Nil
    user = ForumUser.new
    user.username = "Fred"
    # Never persisted, so the UoW has no identifier for it.

    expect_raises(Exception, /Entity has no identity/) do
      @uow.schedule_for_update user
    end
  end

  def test_schedule_for_update_raises_on_entity_scheduled_for_deletion : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, persister

    phone = CmsPhonenumber.new
    phone.phonenumber = "555"

    @uow.persist phone
    @uow.commit
    @uow.schedule_for_delete phone

    expect_raises(Exception, /Entity scheduled for deletion/) do
      @uow.schedule_for_update phone
    end
  end

  def test_schedule_for_update_skips_entities_already_pending_insert : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata VersionedAssignedIdentifierEntity
    @uow.set_entity_persister VersionedAssignedIdentifierEntity, persister

    entity = VersionedAssignedIdentifierEntity.new
    entity.id = 1

    @uow.persist entity
    @uow.is_scheduled_for_insert?(entity).should be_true

    @uow.schedule_for_update entity

    # Insert-pending entities don't double-up as updates — the insert will
    # already write the current state when it executes.
    @uow.is_scheduled_for_update?(entity).should be_false
    @uow.is_scheduled_for_insert?(entity).should be_true
  end

  def test_id_hash_by_identifier_joins_single_key : Nil
    AORM::UnitOfWork.id_hash_by_identifier({"id" => 42}).should eq "42"
  end

  def test_id_hash_by_identifier_joins_composite_keys_with_space : Nil
    # Composite identifier values are flattened into a single space-separated
    # string for use as the identity-map key.
    AORM::UnitOfWork.id_hash_by_identifier({"a" => 1, "b" => 2}).should eq "1 2"
  end

  def test_id_hash_by_identifier_handles_empty_string_single_key : Nil
    AORM::UnitOfWork.id_hash_by_identifier({"id" => ""}).should eq ""
  end

  def test_id_hash_by_identifier_handles_empty_string_composite_keys : Nil
    # Two empty values still produce the separator between them.
    AORM::UnitOfWork.id_hash_by_identifier({"id1" => "", "id2" => ""}).should eq " "
  end

  def test_id_hash_by_identifier_renders_boolean_true_as_1 : Nil
    AORM::UnitOfWork.id_hash_by_identifier({"id" => true}).should eq "1"
  end

  def test_id_hash_by_identifier_renders_boolean_false_as_empty : Nil
    AORM::UnitOfWork.id_hash_by_identifier({"id" => false}).should eq ""
  end

  # ===== Identity map =====

  def test_add_to_identity_map_returns_true_when_inserting_a_new_entry : Nil
    phone = managed_phone "555-0001"

    @uow.is_in_identity_map(phone).should be_true
  end

  def test_add_to_identity_map_is_idempotent_for_the_same_instance : Nil
    phone = managed_phone "555-0002"

    @uow.add_to_identity_map(phone).should be_false
  end

  def test_add_to_identity_map_raises_on_collision_with_a_different_instance : Nil
    managed_phone "555-0003"

    other = CmsPhonenumber.new
    other.phonenumber = "555-0003"
    @uow.@entity_identifiers[other] = {"phonenumber" => AORM::Mapping::ColumnValue.new("phonenumber", "555-0003").as(AORM::Mapping::Value)}

    expect_raises(Exception, /identity collision/) do
      @uow.add_to_identity_map other
    end
  end

  def test_remove_from_identity_map_returns_true_when_present : Nil
    phone = managed_phone "555-0004"

    @uow.remove_from_identity_map(phone).should be_true
    @uow.is_in_identity_map(phone).should be_false
  end

  def test_remove_from_identity_map_returns_false_when_not_present : Nil
    phone = managed_phone "555-0005"
    @uow.remove_from_identity_map phone

    @uow.remove_from_identity_map(phone).should be_false
  end

  def test_get_by_id_hash_returns_entity_for_known_hash : Nil
    phone = managed_phone "555-0006"

    @uow.get_by_id_hash("555-0006", CmsPhonenumber).should be phone
  end

  def test_get_by_id_hash_returns_nil_for_unknown_hash : Nil
    managed_phone "555-0007"

    @uow.get_by_id_hash("nope", CmsPhonenumber).should be_nil
  end

  def test_try_get_by_id_yields_the_entity_when_present : Nil
    phone = managed_phone "555-0008"
    yielded = nil

    @uow.try_get_by_id({"phonenumber" => "555-0008"}, CmsPhonenumber) do |entity|
      yielded = entity
    end

    yielded.should be phone
  end

  def test_try_get_by_id_does_not_yield_when_absent : Nil
    managed_phone "555-0009"
    yielded = false

    @uow.try_get_by_id({"phonenumber" => "missing"}, CmsPhonenumber) { yielded = true }

    yielded.should be_false
  end

  # ===== Entity state =====

  def test_entity_state_is_managed_after_register_managed : Nil
    phone = managed_phone "555-1000"

    @uow.entity_state(phone).should eq AORM::UnitOfWork::EntityState::Managed
  end

  def test_entity_state_returns_assume_when_state_is_unknown : Nil
    user = ForumUser.new

    @uow.entity_state(user, AORM::UnitOfWork::EntityState::Detached).should eq AORM::UnitOfWork::EntityState::Detached
  end

  def test_entity_identifier_returns_the_registered_value : Nil
    phone = managed_phone "555-1001"

    @uow.entity_identifier(phone)["phonenumber"].value.should eq "555-1001"
  end

  def test_entity_identifier_raises_for_an_unknown_entity : Nil
    user = ForumUser.new

    expect_raises(Exception, /Unable to find/) do
      @uow.entity_identifier user
    end
  end

  # Helper: create a CmsPhonenumber, register it as managed with the given id,
  # and return it. Bypasses persistence so identity-map / state tests don't
  # need persister setup.
  private def managed_phone(number : String) : CmsPhonenumber
    phone = CmsPhonenumber.new
    phone.phonenumber = number
    @uow.register_managed phone, {"phonenumber" => number}, {"phonenumber" => number}
    phone
  end

  # ToOne owning-side hydration: when the FK target is already in the identity
  # map, `create_entity` resolves the property inline — no deferred query.
  def test_create_entity_resolves_to_one_owning_side_from_identity_map : Nil
    avatar = ForumAvatar.new
    pointerof(avatar.@id).value = 42
    @uow.register_managed avatar, {"id" => 42}, {"id" => 42}

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(7)
    data["username"] = AORM::Mapping::SingleValue.new("fred")
    # The hydrator's meta-mapping branch deposits FK columns under the
    # column name (not the assoc field name) in the row data hash.
    data["avatar_id"] = AORM::Mapping::SingleValue.new(42)

    user = @uow.create_entity(ForumUser, data).as ForumUser

    user.avatar.should be avatar
    @uow.resolve_pending_to_one_associations
    user.avatar.should be avatar
  end

  # ToOne owning-side hydration: when the FK target isn't in the identity map,
  # the resolution is queued and runs only when the hydrator's `cleanup` fires
  # (driven here by `resolve_pending_to_one_associations`).
  # The persister's `load(id_hash)` is what actually fetches the target.
  def test_create_entity_defers_to_one_owning_side_when_target_not_in_identity_map : Nil
    canned_avatar = ForumAvatar.new
    pointerof(canned_avatar.@id).value = 99

    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ForumAvatar
    avatar_persister.mock_load_result = canned_avatar
    @uow.set_entity_persister ForumAvatar, avatar_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(7)
    data["username"] = AORM::Mapping::SingleValue.new("fred")
    data["avatar_id"] = AORM::Mapping::SingleValue.new(99)

    user = @uow.create_entity(ForumUser, data).as ForumUser

    # Inline access during hydration: the FK target hasn't been fetched yet.
    avatar_persister.load_calls.should be_empty

    # Hydrator's `cleanup` triggers this in real flows; call it directly here.
    @uow.resolve_pending_to_one_associations

    avatar_persister.load_calls.size.should eq 1
    user.avatar.should be canned_avatar
  end

  # Empty-queue commit hits the early-return in `commit`.
  # Nothing is registered, so the call must complete without touching any persister or transaction.
  def test_commit_with_nothing_scheduled_is_a_noop : Nil
    @uow.commit
    @uow.scheduled_entity_insertions.should be_empty
    @uow.scheduled_entity_updates.should be_empty
    @uow.scheduled_entity_deletions.should be_empty
  end

  # `persist` must reject entities the UoW knows are detached.
  # This branch is structurally unreachable from normal flows (`persist` calls `entity_state(entity, :new)`, which short-circuits before the natural-id heuristic), but it's kept as a defensive guard.
  # The test pokes the stored state directly to exercise the defense.
  def test_persist_raises_for_detached_entity : Nil
    user = ForumUser.new
    user.username = "fred"
    @uow.@entity_states[user] = AORM::UnitOfWork::EntityState::Detached

    expect_raises(Exception, "Detached entity ForumUser cannot be persisted") do
      @uow.persist user
    end
  end

  def test_remove_raises_for_detached_entity : Nil
    user = ForumUser.new
    pointerof(user.@id).value = 1

    expect_raises(Exception, "Detached entity ForumUser cannot be removed") do
      @uow.remove user
    end
  end

  # Persisting a loaded proxy unwraps to its inner entity — the inner is what gets queued for insert, never the proxy.
  def test_persist_unwraps_loaded_proxy_to_inner_entity : Nil
    avatar_persister = MockEntityPersister.new @em, @em.class_metadata ForumAvatar
    @uow.set_entity_persister ForumAvatar, avatar_persister
    avatar_persister.mock_id_generator = :identity

    avatar = ForumAvatar.new
    proxy = AORM::Proxy(ForumAvatar).wrap avatar

    @uow.persist proxy

    @uow.scheduled_entity_insertions.includes?(avatar).should be_true
    @uow.scheduled_entity_insertions.includes?(proxy).should be_false
  end

  # Persisting an unfaulted proxy is a no-op.
  # The proxy's target is presumed to already exist in the DB (proxies are only handed out for hydrated rows), so there's nothing to insert.
  def test_persist_on_unfaulted_proxy_is_a_noop : Nil
    proxy = AORM::Proxy(ForumAvatar).from_id @em, {"id" => 99.as(::DB::Any)}

    @uow.persist proxy

    @uow.scheduled_entity_insertions.should be_empty
  end

  # The collection-persister registry only knows about ManyToMany.
  # Feeding it any other association role must raise rather than silently picking the wrong persister.
  def test_collection_persister_raises_for_unsupported_role : Nil
    cm = @em.class_metadata BlogUser
    assoc = cm.association_mappings["posts"].not_nil!

    expect_raises(Exception, /Unsupported collection persister role/) do
      @uow.collection_persister_for assoc
    end
  end

  # Querying a managed-but-unchanged entity for its changeset returns an empty hash — the entity was never tracked into `@entity_change_sets`.
  def test_entity_changeset_returns_empty_for_unchanged_managed_entity : Nil
    phone = managed_phone "555-CS"

    @uow.entity_changeset(phone).should be_empty
  end

  def test_schedule_orphan_removal_adds_to_orphan_removals_set : Nil
    phone = CmsPhonenumber.new
    phone.phonenumber = "555-O"

    @uow.schedule_orphan_removal phone

    @uow.@orphan_removals.includes?(phone).should be_true
  end

  def test_schedule_collection_deletion_adds_to_collection_deletions : Nil
    pc = AORM::PersistentCollection(AORM::Entity).new

    @uow.schedule_collection_deletion pc

    @uow.@collection_deletions.includes?(pc).should be_true
  end

  def test_schedule_collection_update_adds_to_collection_updates : Nil
    pc = AORM::PersistentCollection(AORM::Entity).new

    @uow.schedule_collection_update pc

    @uow.@collection_updates.includes?(pc).should be_true
  end

  # `detach` evicts a managed entity from the UoW: identity map drops it, scheduling sets clear, identifier/state/original-data caches are wiped.
  # The entity object itself is unchanged; callers that hold the reference can keep using it as a plain object.
  def test_detach_clears_managed_entity_from_unit_of_work : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, persister

    phone = managed_phone "555-DETACH"
    @uow.is_in_identity_map(phone).should be_true

    @uow.detach phone

    @uow.is_in_identity_map(phone).should be_false
    @uow.@entity_states.has_key?(phone).should be_false
    @uow.@entity_identifiers.has_key?(phone).should be_false
    @uow.@original_entity_data.has_key?(phone).should be_false
  end

  # Entities scheduled for insert get unqueued by detach, and a subsequent flush must not insert them — the row never gets written.
  def test_detach_drops_pending_insert_and_skips_flush : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata CmsPhonenumber
    @uow.set_entity_persister CmsPhonenumber, persister

    phone = CmsPhonenumber.new
    phone.phonenumber = "555-PENDING"

    @uow.persist phone
    @uow.is_scheduled_for_insert?(phone).should be_true

    @uow.detach phone

    @uow.is_scheduled_for_insert?(phone).should be_false
    @uow.is_in_identity_map(phone).should be_false

    @uow.commit

    persister.inserts.should be_empty
  end

  # New entities (never registered) and already-detached entities are no-ops — detach is idempotent.
  def test_detach_is_a_noop_for_new_entity : Nil
    phone = CmsPhonenumber.new
    phone.phonenumber = "555-NEW"

    @uow.detach phone

    @uow.@entity_states.has_key?(phone).should be_false
  end

  # `add_to_entity_identifier_and_entity_map` reads the entity's already-set ID field, builds an identifier hash, marks the entity managed, populates original entity data, and adds it to the identity map.
  # Reachable in production only through the FK-as-identifier commit path; tested directly here so the contract is locked in.
  def test_add_to_entity_identifier_and_entity_map_registers_single_identifier : Nil
    cm = @em.class_metadata EntityWithStringIdentifier
    entity = EntityWithStringIdentifier.new
    entity.id = "natural-key-1"

    @uow.expose_add_to_entity_identifier_and_entity_map cm, entity

    @uow.is_in_identity_map(entity).should be_true
    @uow.@entity_states[entity].should eq AORM::UnitOfWork::EntityState::Managed
    @uow.entity_identifier(entity)["id"].value.should eq "natural-key-1"
    @uow.@original_entity_data[entity]["id"].value.should eq "natural-key-1"
  end

  # Composite-identifier coverage: every ID field gets its own entry in both `entity_identifiers` and `original_entity_data`.
  def test_add_to_entity_identifier_and_entity_map_registers_composite_identifier : Nil
    cm = @em.class_metadata EntityWithCompositeStringIdentifier
    entity = EntityWithCompositeStringIdentifier.new
    entity.id1 = "tenant-a"
    entity.id2 = "item-42"

    @uow.expose_add_to_entity_identifier_and_entity_map cm, entity

    @uow.is_in_identity_map(entity).should be_true
    identifier = @uow.entity_identifier entity
    identifier["id1"].value.should eq "tenant-a"
    identifier["id2"].value.should eq "item-42"
    @uow.@original_entity_data[entity]["id1"].value.should eq "tenant-a"
    @uow.@original_entity_data[entity]["id2"].value.should eq "item-42"
  end

  # Cascade-detach walks associations whose mapping has `cascade: ["detach"]`, pulling related entities out of the UoW alongside the root.
  def test_detach_cascades_through_cascade_detach_associations : Nil
    owner_persister = MockEntityPersister.new @em, @em.class_metadata DetachOwner
    @uow.set_entity_persister DetachOwner, owner_persister

    target_persister = MockEntityPersister.new @em, @em.class_metadata DetachTarget
    @uow.set_entity_persister DetachTarget, target_persister

    target = DetachTarget.new
    pointerof(target.@id).value = 100

    owner = DetachOwner.new
    pointerof(owner.@id).value = 1
    owner.target = target

    @uow.register_managed owner, {"id" => 1}, {"id" => 1}
    @uow.register_managed target, {"id" => 100}, {"id" => 100}

    @uow.detach owner

    @uow.is_in_identity_map(owner).should be_false
    @uow.is_in_identity_map(target).should be_false
  end

  # `cascade_remove` walks every association tagged with `cascade: ["remove"]` and routes each related entity through the same `remove` path.
  # Both the root and its cascade-tracked targets land in `entity_deletions`.
  def test_remove_cascades_to_targets_when_cascade_remove_is_configured : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CascadeRemoveUser
    @uow.set_entity_persister CascadeRemoveUser, user_persister

    group_persister = MockEntityPersister.new @em, @em.class_metadata CmsGroup
    @uow.set_entity_persister CmsGroup, group_persister

    user = CascadeRemoveUser.new
    user.username = "fred"
    pointerof(user.@id).value = 1

    g1 = CmsGroup.new
    g1.name = "admins"
    pointerof(g1.@id).value = 10

    g2 = CmsGroup.new
    g2.name = "devs"
    pointerof(g2.@id).value = 20

    user.groups << g1
    user.groups << g2

    @uow.register_managed user, {"id" => 1}, {"id" => 1, "username" => "fred"}
    @uow.register_managed g1, {"id" => 10}, {"id" => 10, "name" => "admins"}
    @uow.register_managed g2, {"id" => 20}, {"id" => 20, "name" => "devs"}

    @uow.remove user

    @uow.scheduled_entity_deletions.includes?(user).should be_true
    @uow.scheduled_entity_deletions.includes?(g1).should be_true
    @uow.scheduled_entity_deletions.includes?(g2).should be_true
  end

  # `load_collection` delegates to the entity persister's `load_many_to_many_collection` for ManyToMany associations and flips the collection's `initialized` flag once the load returns.
  def test_load_collection_delegates_to_persister_and_marks_initialized : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister

    group_persister = CollectionAddingPersister.new @em, @em.class_metadata(CmsGroup)
    @uow.set_entity_persister CmsGroup, group_persister

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(7)
    data["username"] = AORM::Mapping::SingleValue.new("fred")
    user = @uow.create_entity(CmsUser, data).as CmsUser
    pc = user.groups.as(AORM::PersistentCollection(CmsGroup))
    pc.loaded?.should be_false

    @uow.load_collection pc

    group_persister.load_many_to_many_called?.should be_true
    pc.loaded?.should be_true
  end

  # The inverse side of a OneToOne queues a pending resolution with `target_id: nil`.
  # `resolve_pending_to_one_associations` then dispatches that resolution through `entity_persister(target).load_one_to_one_entity` rather than a primary-key load.
  def test_resolve_pending_to_one_associations_uses_load_one_to_one_for_inverse_side : Nil
    target_persister = MockEntityPersister.new @em, @em.class_metadata InverseO2OTarget
    @uow.set_entity_persister InverseO2OTarget, target_persister

    capturing = CapturingOneToOnePersister.new @em, @em.class_metadata(InverseO2OOwner)
    @uow.set_entity_persister InverseO2OOwner, capturing

    data = Hash(String, AORM::Mapping::Value).new
    data["id"] = AORM::Mapping::SingleValue.new(3)
    target = @uow.create_entity(InverseO2OTarget, data).as InverseO2OTarget

    capturing.one_to_one_calls.should be_empty

    @uow.resolve_pending_to_one_associations

    capturing.one_to_one_calls.size.should eq 1
    capturing.one_to_one_calls.first.source.should be target
    capturing.one_to_one_calls.first.assoc.mapped_by.should eq "target"
  end

  # Reassigning a managed PersistentCollection from one owner to another must clone it for the new owner and queue the original for deletion, so each owner's join-table rows stay tied to the right owner.
  def test_compute_change_set_clones_collection_and_schedules_old_for_deletion_on_owner_reassignment : Nil
    user_persister = MockEntityPersister.new @em, @em.class_metadata CmsUser
    @uow.set_entity_persister CmsUser, user_persister

    # Empty result so `initialize_collection` (forced before the clone) doesn't crash.
    group_persister = CollectionAddingPersister.new @em, @em.class_metadata(CmsGroup)
    @uow.set_entity_persister CmsGroup, group_persister

    data1 = Hash(String, AORM::Mapping::Value).new
    data1["id"] = AORM::Mapping::SingleValue.new(1)
    data1["username"] = AORM::Mapping::SingleValue.new("alice")
    user1 = @uow.create_entity(CmsUser, data1).as CmsUser
    pc1 = user1.groups.as(AORM::PersistentCollection(CmsGroup))

    data2 = Hash(String, AORM::Mapping::Value).new
    data2["id"] = AORM::Mapping::SingleValue.new(2)
    data2["username"] = AORM::Mapping::SingleValue.new("bob")
    user2 = @uow.create_entity(CmsUser, data2).as CmsUser
    pc2 = user2.groups.as(AORM::PersistentCollection(CmsGroup))

    # Hand alice's collection to bob — this is the scenario the change-set logic must defend against.
    user2.groups = pc1

    @uow.compute_changesets

    @uow.@collection_deletions.includes?(pc2).should be_true
    user2.groups.should_not be pc1
    user2.groups.as(AORM::PersistentCollection(CmsGroup)).owner.should be user2
  end
end

# Helper persister that throws an exception during execute_inserts
class FailingEntityPersister < MockEntityPersister
  def initialize(@em : AORM::EntityManagerInterface, @class_metadata : AORM::Mapping::ClassInterface, @error_message : String)
    super(@em, @class_metadata)
  end

  def execute_inserts : Nil
    raise @error_message
  end
end
