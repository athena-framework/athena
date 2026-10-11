require "../spec_helper"
require "../../src/spec"

# Gets its entity manager factory from each test, so a test can drive the test case one step at a time.
@[ASPEC::TestCase::Skip]
struct ConfigurableDBTestCase < AORM::Spec::DBTestCase
  property! entity_manager_factory : AORM::EntityManagerFactory
end

struct DBTestCaseTest < ASPEC::TestCase
  @database : DB::Database
  @test_case : ConfigurableDBTestCase

  def initialize
    @database = DB::Database.new(DB::Connection::Options.new, DB::Pool::Options.new(initial_pool_size: 0)) { MockConnection.new.as(DB::Connection) }
    @test_case = ConfigurableDBTestCase.new
    @test_case.entity_manager_factory = AORM::EntityManagerFactory.new @database
  end

  def tear_down : Nil
    @test_case.tear_down
  end

  def test_entity_manager_begins_a_transaction : Nil
    connection = @test_case.em.connection

    connection.transaction_nesting_level.should eq 1
    connection.wrapped.as(MockConnection).executed_statements.map(&.[0]).should eq ["BEGIN"]
  end

  def test_entity_manager_is_created_once_per_test : Nil
    @test_case.em.should be @test_case.em
    self.checked_out_connections(@database).should eq 1
  end

  def test_entity_manager_releases_the_connection_if_it_cannot_be_created : Nil
    database = DB::Database.new(DB::Connection::Options.new, DB::Pool::Options.new) { MockConnection.new(driver_name: "unknown").as(DB::Connection) }
    @test_case.entity_manager_factory = AORM::EntityManagerFactory.new database

    expect_raises AORM::Exceptions::UnknownDriver do
      @test_case.em
    end

    self.checked_out_connections(database).should eq 0
  end

  # A transaction the code under test left open must not outlive the test either.
  def test_tear_down_rolls_back_every_transaction : Nil
    em = @test_case.em
    em.begin_transaction

    @test_case.tear_down

    em.connection.transaction_active?.should be_false
    em.connection.wrapped.as(MockConnection).executed_statements.last[0].should eq "ROLLBACK"
  end

  def test_tear_down_closes_the_entity_manager_and_releases_its_connection : Nil
    em = @test_case.em

    @test_case.tear_down

    em.closed?.should be_true
    self.checked_out_connections(@database).should eq 0
  end

  def test_tear_down_resets_the_entity_manager_for_the_next_test : Nil
    em = @test_case.em

    @test_case.tear_down

    @test_case.em.should_not be em
  end

  def test_tear_down_checks_out_no_connection_if_the_entity_manager_was_not_used : Nil
    @test_case.tear_down

    @database.pool.stats.open_connections.should eq 0
  end

  private def checked_out_connections(database : DB::Database) : Int32
    stats = database.pool.stats

    stats.open_connections - stats.idle_connections
  end
end
