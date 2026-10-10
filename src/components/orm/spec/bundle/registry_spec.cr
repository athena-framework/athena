require "./spec_helper"

private class MockEventDispatcher
  include ACTR::EventDispatcher::Interface

  def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
    event
  end
end

describe AORM::Bundle::Registry do
  describe "#manager" do
    it "creates the entity manager once, on a connection checked out from the pool" do
      event_dispatcher = MockEventDispatcher.new
      registry = AORM::Bundle::Registry.new "mock://", event_dispatcher

      entity_manager = registry.manager

      registry.manager.should be entity_manager
      entity_manager.event_dispatcher.should be event_dispatcher
      entity_manager.connection.wrapped.should be_a PooledMockConnection
    ensure
      registry.try &.close
    end

    it "shares the connection pool between registries" do
      registry = AORM::Bundle::Registry.new "mock://"
      connection = registry.manager.connection.wrapped
      registry.close

      other_registry = AORM::Bundle::Registry.new "mock://"
      other_registry.manager.connection.wrapped.should be connection
    ensure
      other_registry.try &.close
    end

    it "releases the connection if the entity manager can't be created" do
      registry = AORM::Bundle::Registry.new "mock://"
      connection = registry.manager.connection.wrapped.as PooledMockConnection
      registry.close

      # The pool hands the same, now idle, connection out next.
      connection.driver_name = "unknown"
      released = PooledMockConnection.released

      expect_raises AORM::Exceptions::UnknownDriver do
        registry.manager
      end

      PooledMockConnection.released.should eq released + 1
    ensure
      connection.try &.driver_name = "sqlite3"
    end
  end

  describe "#close" do
    it "rolls back an open transaction, closes the entity manager, and releases its connection" do
      registry = AORM::Bundle::Registry.new "mock://"
      entity_manager = registry.manager
      connection = entity_manager.connection.wrapped.as PooledMockConnection
      released = PooledMockConnection.released

      # The connection may have been used by another spec before being returned to the pool.
      connection.executed_statements.clear

      entity_manager.begin_transaction
      registry.close

      connection.executed_statements.map(&.first).should eq ["BEGIN", "ROLLBACK"]
      entity_manager.closed?.should be_true
      PooledMockConnection.released.should eq released + 1
    end

    it "creates a new entity manager once closed" do
      registry = AORM::Bundle::Registry.new "mock://"
      entity_manager = registry.manager

      registry.close

      registry.manager.should_not be entity_manager
    ensure
      registry.try &.close
    end

    it "does nothing if the entity manager wasn't created" do
      released = PooledMockConnection.released

      AORM::Bundle::Registry.new("mock://").close

      PooledMockConnection.released.should eq released
    end
  end
end
