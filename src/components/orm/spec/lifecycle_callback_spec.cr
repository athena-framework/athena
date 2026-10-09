require "./spec_helper"
require "uuid"

# Inline test entities — kept here rather than under spec/models/ because they
# only matter to this file's coverage of lifecycle callback invocation.
@[AORMA::Entity]
class LifecycleCallbackTestEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  @[AORMA::Column]
  property value : String = ""

  property pre_persist_invoked : Bool = false
  property pre_persist_args_ok : Bool = false
  property post_persist_invoked : Bool = false
  property post_persist_args_ok : Bool = false
  property pre_update_invoked : Bool = false
  property pre_update_args_ok : Bool = false
  property post_update_invoked : Bool = false
  property post_update_args_ok : Bool = false
  property pre_remove_invoked : Bool = false
  property pre_remove_args_ok : Bool = false
  property post_remove_invoked : Bool = false
  property post_remove_args_ok : Bool = false
  property pre_flush_invoked : Bool = false
  property pre_flush_args_ok : Bool = false

  def initialize
    @id = "Lifecycle-#{UUID.random}"
  end

  @[AORMA::PreFlush]
  def on_pre_flush(event : AORM::Events::PreFlushEventArgs) : Nil
    @pre_flush_invoked = true
    @pre_flush_args_ok = !event.entity_manager.nil?
  end

  @[AORMA::PrePersist]
  def on_pre_persist(event : AORM::Events::PrePersistEventArgs(LifecycleCallbackTestEntity)) : Nil
    @pre_persist_invoked = true
    @pre_persist_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end

  @[AORMA::PostPersist]
  def on_post_persist(event : AORM::Events::PostPersistEventArgs(LifecycleCallbackTestEntity)) : Nil
    @post_persist_invoked = true
    @post_persist_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end

  @[AORMA::PreUpdate]
  def on_pre_update(event : AORM::Events::PreUpdateEventArgs(LifecycleCallbackTestEntity)) : Nil
    @pre_update_invoked = true
    @pre_update_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end

  @[AORMA::PostUpdate]
  def on_post_update(event : AORM::Events::PostUpdateEventArgs(LifecycleCallbackTestEntity)) : Nil
    @post_update_invoked = true
    @post_update_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end

  @[AORMA::PreRemove]
  def on_pre_remove(event : AORM::Events::PreRemoveEventArgs(LifecycleCallbackTestEntity)) : Nil
    @pre_remove_invoked = true
    @pre_remove_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end

  @[AORMA::PostRemove]
  def on_post_remove(event : AORM::Events::PostRemoveEventArgs(LifecycleCallbackTestEntity)) : Nil
    @post_remove_invoked = true
    @post_remove_args_ok = event.entity.same?(self) && !event.entity_manager.nil?
  end
end

# Mirror of `LifecycleCallbackTestEntity` whose callback methods take no
# event parameter — exercises the macro branch that omits the event arg.
@[AORMA::Entity]
class LifecycleCallbackNoArgEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  @[AORMA::Column]
  property value : String = ""

  property pre_persist_invoked : Bool = false
  property post_persist_invoked : Bool = false
  property pre_update_invoked : Bool = false
  property post_update_invoked : Bool = false
  property pre_remove_invoked : Bool = false
  property post_remove_invoked : Bool = false
  property pre_flush_invoked : Bool = false

  def initialize
    @id = "NoArg-#{UUID.random}"
  end

  @[AORMA::PreFlush]
  def on_pre_flush : Nil
    @pre_flush_invoked = true
  end

  @[AORMA::PrePersist]
  def on_pre_persist : Nil
    @pre_persist_invoked = true
  end

  @[AORMA::PostPersist]
  def on_post_persist : Nil
    @post_persist_invoked = true
  end

  @[AORMA::PreUpdate]
  def on_pre_update : Nil
    @pre_update_invoked = true
  end

  @[AORMA::PostUpdate]
  def on_post_update : Nil
    @post_update_invoked = true
  end

  @[AORMA::PreRemove]
  def on_pre_remove : Nil
    @pre_remove_invoked = true
  end

  @[AORMA::PostRemove]
  def on_post_remove : Nil
    @post_remove_invoked = true
  end
end

# An entity with multiple methods sharing the same callback annotation, used
# to verify all matching callbacks fire on dispatch.
@[AORMA::Entity]
class LifecycleCallbackMultiplePostPersist < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  property first_call_count : Int32 = 0
  property second_call_count : Int32 = 0

  def initialize
    @id = "Multi-#{UUID.random}"
  end

  @[AORMA::PostPersist]
  def first_post_persist : Nil
    @first_call_count += 1
  end

  @[AORMA::PostPersist]
  def second_post_persist : Nil
    @second_call_count += 1
  end
end

# Callbacks declared in a module, used to verify an including entity registers them.
module LifecycleCallbackCounting
  property module_pre_persist_count : Int32 = 0
  property overridden_pre_persist_count : Int32 = 0

  @[AORMA::PrePersist]
  def module_pre_persist : Nil
    @module_pre_persist_count += 1
  end

  @[AORMA::PrePersist]
  def overridden_pre_persist : Nil
    @overridden_pre_persist_count += 100
  end

  @[AORMA::PrePersist]
  def silenced_pre_persist : Nil
  end
end

@[AORMA::Entity]
class LifecycleCallbackFromModule < AORM::Entity
  include LifecycleCallbackCounting

  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  def initialize
    @id = "Module-#{UUID.random}"
  end

  # Overrides keep the module's callback only if they keep its annotation.
  @[AORMA::PrePersist]
  def overridden_pre_persist : Nil
    @overridden_pre_persist_count += 1
  end

  def silenced_pre_persist : Nil
  end
end

# Callbacks declared on an abstract parent, used to verify an inheriting entity registers them.
abstract class LifecycleCallbackParent < AORM::Entity
  property parent_pre_persist_count : Int32 = 0

  @[AORMA::PrePersist]
  def parent_pre_persist : Nil
    @parent_pre_persist_count += 1
  end
end

@[AORMA::Entity]
class LifecycleCallbackFromParent < LifecycleCallbackParent
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : String? = nil

  def initialize
    @id = "Parent-#{UUID.random}"
  end
end

struct LifecycleCallbackTest < ASPEC::TestCase
  @connection : MockConnection
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @connection = MockConnection.new
    @em = MockEntityManager.new @connection
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  def test_lifecycle_callbacks_registered_on_class_metadata : Nil
    metadata = @em.class_metadata LifecycleCallbackTestEntity
    keys = metadata.lifecycle_callbacks.keys

    keys.should contain AORM::Events::PrePersistEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PostPersistEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PreUpdateEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PostUpdateEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PreRemoveEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PostRemoveEventArgs(LifecycleCallbackTestEntity)
    keys.should contain AORM::Events::PreFlushEventArgs
  end

  def test_entity_without_callbacks_has_no_registered_callbacks : Nil
    metadata = @em.class_metadata ForumUser
    metadata.lifecycle_callbacks.empty?.should be_true
  end

  def test_pre_persist_invoked_with_args_on_persist : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @uow.persist entity

    entity.pre_persist_invoked.should be_true
    entity.pre_persist_args_ok.should be_true
  end

  def test_post_persist_invoked_with_args_after_commit : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @uow.persist entity

    # Not yet committed — postPersist hasn't fired.
    entity.post_persist_invoked.should be_false

    @uow.commit
    entity.post_persist_invoked.should be_true
    entity.post_persist_args_ok.should be_true
  end

  def test_pre_update_and_post_update_invoked_with_args_on_update_flush : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    entity.value = "initial"
    @uow.persist entity
    @uow.commit

    entity.pre_update_invoked.should be_false
    entity.post_update_invoked.should be_false

    entity.value = "updated"
    @uow.commit

    entity.pre_update_invoked.should be_true
    entity.pre_update_args_ok.should be_true
    entity.post_update_invoked.should be_true
    entity.post_update_args_ok.should be_true
  end

  def test_pre_remove_invoked_with_args_when_remove_called : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @uow.persist entity
    @uow.commit

    @uow.remove entity
    entity.pre_remove_invoked.should be_true
    entity.pre_remove_args_ok.should be_true
    entity.post_remove_invoked.should be_false
  end

  def test_post_remove_invoked_with_args_after_delete_commit : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @uow.persist entity
    @uow.commit

    @uow.remove entity
    @uow.commit
    entity.post_remove_invoked.should be_true
    entity.post_remove_args_ok.should be_true
  end

  def test_no_arg_pre_persist_invoked_on_persist : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    @uow.persist entity

    entity.pre_persist_invoked.should be_true
  end

  def test_no_arg_post_persist_invoked_after_commit : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    @uow.persist entity
    @uow.commit

    entity.post_persist_invoked.should be_true
  end

  def test_no_arg_pre_update_and_post_update_invoked_on_update_flush : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    entity.value = "initial"
    @uow.persist entity
    @uow.commit

    entity.pre_update_invoked.should be_false
    entity.post_update_invoked.should be_false

    entity.value = "updated"
    @uow.commit

    entity.pre_update_invoked.should be_true
    entity.post_update_invoked.should be_true
  end

  def test_no_arg_pre_remove_invoked_when_remove_called : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    @uow.persist entity
    @uow.commit

    @uow.remove entity
    entity.pre_remove_invoked.should be_true
    entity.post_remove_invoked.should be_false
  end

  def test_pre_flush_invoked_with_args_on_every_flush : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    entity.value = "hello"
    @uow.persist entity

    # First flush: entity is new, scheduled for insert.
    @uow.commit
    entity.pre_flush_invoked.should be_true
    entity.pre_flush_args_ok.should be_true

    # Second flush: entity is managed, no changes.
    entity.pre_flush_invoked = false
    @uow.commit
    entity.pre_flush_invoked.should be_true

    # Third flush: entity is managed, dirty.
    entity.value = "bye"
    entity.pre_flush_invoked = false
    @uow.commit
    entity.pre_flush_invoked.should be_true
  end

  def test_no_arg_pre_flush_invoked_on_every_flush : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    entity.value = "hello"
    @uow.persist entity

    @uow.commit
    entity.pre_flush_invoked.should be_true

    entity.pre_flush_invoked = false
    @uow.commit
    entity.pre_flush_invoked.should be_true

    entity.value = "bye"
    entity.pre_flush_invoked = false
    @uow.commit
    entity.pre_flush_invoked.should be_true
  end

  def test_no_arg_post_remove_invoked_after_delete_commit : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackNoArgEntity
    @uow.set_entity_persister LifecycleCallbackNoArgEntity, persister

    entity = LifecycleCallbackNoArgEntity.new
    @uow.persist entity
    @uow.commit

    @uow.remove entity
    @uow.commit
    entity.post_remove_invoked.should be_true
  end

  def test_multiple_callbacks_with_same_annotation_all_fire : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackMultiplePostPersist
    @uow.set_entity_persister LifecycleCallbackMultiplePostPersist, persister

    entity = LifecycleCallbackMultiplePostPersist.new
    @uow.persist entity
    @uow.commit

    entity.first_call_count.should eq 1
    entity.second_call_count.should eq 1
  end

  def test_callbacks_from_included_modules_fire : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackFromModule
    @uow.set_entity_persister LifecycleCallbackFromModule, persister

    entity = LifecycleCallbackFromModule.new
    @uow.persist entity

    entity.module_pre_persist_count.should eq 1
    entity.overridden_pre_persist_count.should eq 1
  end

  def test_callbacks_from_an_abstract_parent_fire : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackFromParent
    @uow.set_entity_persister LifecycleCallbackFromParent, persister

    entity = LifecycleCallbackFromParent.new
    @uow.persist entity

    entity.parent_pre_persist_count.should eq 1
  end

  def test_overriding_a_module_callback_without_its_annotation_drops_it : Nil
    metadata = @em.class_metadata LifecycleCallbackFromModule

    metadata.lifecycle_callbacks[AORM::Events::PrePersistEventArgs(LifecycleCallbackFromModule)].size.should eq 2
  end

  # `EntityManager#persist` and `#remove` pass the unit of work an `AORM::Entity`, as do cascades, so callbacks have to be found from the entity's runtime class.
  def test_pre_persist_invoked_when_persisted_through_the_entity_manager : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @em.persist entity

    entity.pre_persist_invoked.should be_true
    entity.pre_persist_args_ok.should be_true
  end

  def test_pre_remove_invoked_when_removed_through_the_entity_manager : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata LifecycleCallbackTestEntity
    @uow.set_entity_persister LifecycleCallbackTestEntity, persister

    entity = LifecycleCallbackTestEntity.new
    @em.persist entity
    @uow.commit

    @em.remove entity
    entity.pre_remove_invoked.should be_true
    entity.pre_remove_args_ok.should be_true
  end
end
