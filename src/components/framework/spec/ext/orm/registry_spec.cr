require "../../spec_helper"

describe ATH::ORM::Registry do
  describe "#manager" do
    it "creates the entity manager once, on a connection checked out from the pool" do
      event_dispatcher = AED::EventDispatcher.new
      registry = ATH::ORM::Registry.new "mock://", event_dispatcher

      entity_manager = registry.manager

      registry.manager.should be entity_manager
      entity_manager.event_dispatcher.should be event_dispatcher
      entity_manager.connection.wrapped.should be_a MockConnection
    ensure
      registry.try &.close
    end

    it "shares the connection pool between registries" do
      ATH::ORM::Registry.new("mock://", AED::EventDispatcher.new).tap(&.manager).close

      built = MockConnection.built

      registry = ATH::ORM::Registry.new "mock://", AED::EventDispatcher.new
      registry.manager
      registry.close

      MockConnection.built.should eq built
    end

    it "releases the connection if the entity manager can't be created" do
      registry = ATH::ORM::Registry.new "mock://", AED::EventDispatcher.new
      released = MockConnection.released
      MockConnection.driver_name = "unknown"

      expect_raises AORM::Exceptions::UnknownDriver do
        registry.manager
      end

      MockConnection.released.should eq released + 1
    ensure
      MockConnection.driver_name = "sqlite3"
    end
  end

  describe "#close" do
    it "rolls back an open transaction, closes the entity manager, and releases its connection" do
      registry = ATH::ORM::Registry.new "mock://", AED::EventDispatcher.new
      entity_manager = registry.manager
      connection = entity_manager.connection.wrapped.as MockConnection
      released = MockConnection.released

      # The connection may have been used by another spec before being returned to the pool.
      connection.executed_statements.clear

      entity_manager.begin_transaction
      registry.close

      connection.executed_statements.should eq ["BEGIN", "ROLLBACK"]
      entity_manager.closed?.should be_true
      MockConnection.released.should eq released + 1
    end

    it "creates a new entity manager once closed" do
      registry = ATH::ORM::Registry.new "mock://", AED::EventDispatcher.new
      entity_manager = registry.manager

      registry.close

      registry.manager.should_not be entity_manager
    ensure
      registry.try &.close
    end

    it "does nothing if the entity manager wasn't created" do
      released = MockConnection.released

      ATH::ORM::Registry.new("mock://", AED::EventDispatcher.new).close

      MockConnection.released.should eq released
    end
  end
end
