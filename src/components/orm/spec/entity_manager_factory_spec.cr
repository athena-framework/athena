require "./spec_helper"

private class MockEventDispatcher
  include ACTR::EventDispatcher::Interface

  def dispatch(event : ACTR::EventDispatcher::Event) : ACTR::EventDispatcher::Event
    event
  end
end

struct EntityManagerFactoryTest < ASPEC::TestCase
  @database : DB::Database
  @factory : AORM::EntityManagerFactory

  def initialize
    @database = DB::Database.new(DB::Connection::Options.new, DB::Pool::Options.new) { MockConnection.new.as(DB::Connection) }
    @factory = AORM::EntityManagerFactory.new @database
  end

  def test_create_entity_manager : Nil
    connection = MockConnection.new
    event_dispatcher = MockEventDispatcher.new
    factory = AORM::EntityManagerFactory.new @database, event_dispatcher

    em = factory.create_entity_manager connection

    em.connection.wrapped.should be connection
    em.event_dispatcher.should be event_dispatcher
    em.class_metadata(ForumUser).should be factory.create_entity_manager(MockConnection.new).class_metadata(ForumUser)
  end

  def test_with_entity_manager_returns_the_block_value : Nil
    @factory.with_entity_manager(&.closed?).should be_false
  end

  def test_with_entity_manager_closes_the_entity_manager_and_releases_its_connection : Nil
    em = @factory.with_entity_manager { |entity_manager| entity_manager }

    em.closed?.should be_true
    @database.pool.stats.in_flight_connections.should eq 0
  end

  def test_with_entity_manager_releases_the_connection_when_the_block_raises : Nil
    expect_raises(Exception, "boom") do
      @factory.with_entity_manager { raise "boom" }
    end

    @database.pool.stats.in_flight_connections.should eq 0
  end

  # A pooled connection must not reach its next user with a transaction open.
  def test_with_entity_manager_rolls_back_transactions_the_block_left_open : Nil
    connection = @factory.with_entity_manager do |em|
      em.begin_transaction
      em.begin_transaction
      em.connection
    end

    connection.transaction_active?.should be_false
  end

  def test_entity_managers_share_class_metadata : Nil
    first = @factory.with_entity_manager(&.class_metadata(ForumUser))
    second = @factory.with_entity_manager(&.class_metadata(ForumUser))

    first.should be second
  end
end
