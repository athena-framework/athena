require "./spec_helper"

# Records every event it dispatches, so specs can assert which global ORM events fired in which order during commit / clear.
private class RecordingEventDispatcher
  include ACTR::EventDispatcher::Interface

  getter events : Array(ACTR::EventDispatcher::Event) = [] of ACTR::EventDispatcher::Event

  # Called with each `OnFlushEventArgs`, acting as a listener.
  property on_flush : Proc(AORM::Events::OnFlushEventArgs, Nil)? = nil

  def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
    @events << event

    if event.is_a?(AORM::Events::OnFlushEventArgs) && (on_flush = @on_flush)
      on_flush.call event
    end

    event
  end

  def event_classes : Array(String)
    @events.map &.class.name
  end

  def reset : Nil
    @events.clear
  end
end

@[AORMA::Entity]
class FlushEventTestEntity < AORM::Entity
  @[AORMA::Column]
  @[AORMA::ID]
  @[AORMA::GeneratedValue(strategy: :none)]
  property id : Int32? = nil

  @[AORMA::Column]
  property value : String = ""
end

struct FlushEventTest < ASPEC::TestCase
  @connection : MockConnection
  @dispatcher : RecordingEventDispatcher
  @em : MockEntityManager
  @uow : MockUnitOfWork

  def initialize
    @connection = MockConnection.new
    @dispatcher = RecordingEventDispatcher.new
    @em = MockEntityManager.new @connection, @dispatcher
    @uow = MockUnitOfWork.new @em
    @em.uow_mock = @uow
  end

  def test_pre_on_post_flush_dispatched_in_order_with_entities : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata FlushEventTestEntity
    @uow.set_entity_persister FlushEventTestEntity, persister

    entity = FlushEventTestEntity.new
    entity.id = 1
    @uow.persist entity

    @uow.commit

    @dispatcher.event_classes.should eq [
      "Athena::ORM::Events::PreFlushEventArgs",
      "Athena::ORM::Events::OnFlushEventArgs",
      "Athena::ORM::Events::PostFlushEventArgs",
    ]
  end

  def test_pre_on_post_flush_dispatched_when_nothing_to_flush : Nil
    @uow.commit

    @dispatcher.event_classes.should eq [
      "Athena::ORM::Events::PreFlushEventArgs",
      "Athena::ORM::Events::OnFlushEventArgs",
      "Athena::ORM::Events::PostFlushEventArgs",
    ]
  end

  def test_pre_and_on_flush_called_each_commit : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata FlushEventTestEntity
    @uow.set_entity_persister FlushEventTestEntity, persister

    @uow.commit
    @uow.commit

    pre_flush_count = @dispatcher.events.count &.is_a?(AORM::Events::PreFlushEventArgs)
    on_flush_count = @dispatcher.events.count &.is_a?(AORM::Events::OnFlushEventArgs)
    post_flush_count = @dispatcher.events.count &.is_a?(AORM::Events::PostFlushEventArgs)

    pre_flush_count.should eq 2
    on_flush_count.should eq 2
    post_flush_count.should eq 2
  end

  def test_dispatched_events_carry_entity_manager : Nil
    @uow.commit

    @dispatcher.events.each do |event|
      next unless event.is_a?(AORM::Events::ManagerEventArgs)
      event.entity_manager.should be @em
    end
  end

  def test_no_events_dispatched_when_dispatcher_not_configured : Nil
    em_without_dispatcher = MockEntityManager.new MockConnection.new
    uow = MockUnitOfWork.new em_without_dispatcher
    em_without_dispatcher.uow_mock = uow

    # Should not raise.
    uow.commit
  end

  def test_on_clear_dispatched_on_em_clear : Nil
    @em.clear

    @dispatcher.event_classes.should contain "Athena::ORM::Events::OnClearEventArgs"
  end

  def test_on_clear_event_carries_entity_manager : Nil
    @em.clear

    on_clear = @dispatcher.events.find &.is_a?(AORM::Events::OnClearEventArgs)
    on_clear.should_not be_nil
    on_clear.as(AORM::Events::OnClearEventArgs).entity_manager.should be @em
  end

  def test_on_flush_listener_can_read_scheduled_insertions : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata FlushEventTestEntity
    @uow.set_entity_persister FlushEventTestEntity, persister

    entity = FlushEventTestEntity.new
    entity.id = 1
    @uow.persist entity

    @uow.commit

    on_flush = @dispatcher.events.find &.is_a?(AORM::Events::OnFlushEventArgs)
    on_flush.should_not be_nil

    # By the time onFlush dispatches, scheduled insertions are still
    # populated — listeners can iterate them and inject extra work.
    em = on_flush.as(AORM::Events::OnFlushEventArgs).entity_manager
    em.should be @em
  end

  # Change sets are computed before OnFlush is dispatched, so a listener that persists an entity computes its change set itself.
  def test_on_flush_listener_persists_an_entity_by_computing_its_change_set : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata FlushEventTestEntity
    @uow.set_entity_persister FlushEventTestEntity, persister

    added = FlushEventTestEntity.new
    added.id = 2
    added.value = "added on flush"

    @dispatcher.on_flush = ->(event : AORM::Events::OnFlushEventArgs) do
      em = event.entity_manager
      em.persist added
      em.unit_of_work.compute_change_set em.class_metadata(FlushEventTestEntity), added
      nil
    end

    entity = FlushEventTestEntity.new
    entity.id = 1
    @uow.persist entity
    @uow.commit

    persister.inserts.should eq [entity, added]
    persister.insert_data.last["flush_event_test_entity"]["value"].value.should eq "added on flush"
  end

  # A listener that changes a managed entity recomputes its change set, which schedules the entity for update.
  def test_on_flush_listener_updates_an_entity_by_recomputing_its_change_set : Nil
    persister = MockEntityPersister.new @em, @em.class_metadata FlushEventTestEntity
    @uow.set_entity_persister FlushEventTestEntity, persister

    managed = FlushEventTestEntity.new
    managed.id = 1
    managed.value = "original"
    @uow.register_managed managed, {"id" => 1}, {"id" => 1, "value" => "original"}

    @dispatcher.on_flush = ->(event : AORM::Events::OnFlushEventArgs) do
      managed.value = "changed on flush"
      event.entity_manager.unit_of_work.recompute_single_entity_change_set event.entity_manager.class_metadata(FlushEventTestEntity), managed
      nil
    end

    # Something else to flush, since a flush with nothing to write ends after dispatching OnFlush.
    other = FlushEventTestEntity.new
    other.id = 2
    @uow.persist other
    @uow.commit

    persister.updates.should eq [managed]
    persister.update_data.last["flush_event_test_entity"]["value"].value.should eq "changed on flush"
  end
end
