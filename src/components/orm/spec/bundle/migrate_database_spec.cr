require "./spec_helper"
require "../../src/migrations"
require "../../src/spec"

class App::Migrations::Version1 < AORM::Migrations::AbstractMigration
  class_property? abort = false

  def up : Nil
    self.abort_if @@abort, "Aborted"
    self.add_sql "CREATE TABLE a (id INTEGER)"
  end
end

private NO_ROWS = [] of Hash(String, DB::Any)

private def rows(*rows : Hash(String, _)) : Array(Hash(String, DB::Any))
  rows.map(&.transform_values(&.as(DB::Any))).to_a
end

struct MigrateDatabaseTest < ASPEC::TestCase
  @container : ADI::ServiceContainer
  @connection : PooledMockConnection

  def initialize
    @container = ADI::ServiceContainer.new
    @connection = @container.athena_orm_registry.manager.connection.wrapped.as PooledMockConnection

    # The connection may have been used by an earlier test.
    @connection.executed_statements.clear
  end

  def tear_down : Nil
    App::Migrations::Version1.abort = false
    @container.athena_dependency_injection_services_closer.close
  end

  # Queues the results of checking for the version table, and of listing the executed migrations, which resolving the latest version and planning the migrations each do.
  private def queue_database(*, versions_table : Bool, executed : Array(Hash(String, DB::Any)) = NO_ROWS) : Nil
    @connection.queue_result versions_table ? rows({"name" => "athena_orm_migration_versions"}) : NO_ROWS
    2.times { @connection.queue_result executed }
  end

  def test_executes_the_migrations_not_executed_yet : Nil
    self.queue_database versions_table: false

    AORM::Spec.migrate_database @container

    statements = @connection.executed_statements.map &.[0]
    statements.count(&.starts_with?("CREATE TABLE athena_orm_migration_versions")).should eq 1
    statements.should contain "CREATE TABLE a (id INTEGER)"
    statements.count(&.starts_with?("INSERT INTO athena_orm_migration_versions")).should eq 1
  end

  def test_does_nothing_once_up_to_date : Nil
    self.queue_database versions_table: true, executed: rows({"version" => "App::Migrations::Version1", "executed_at" => nil, "execution_time" => nil})

    AORM::Spec.migrate_database @container

    @connection.executed_statements.none?(&.[0].starts_with?("CREATE TABLE")).should be_true
    @connection.executed_statements.none?(&.[0].starts_with?("INSERT")).should be_true
  end

  def test_closes_the_services_of_the_container : Nil
    self.queue_database versions_table: true, executed: rows({"version" => "App::Migrations::Version1", "executed_at" => nil, "execution_time" => nil})
    released = PooledMockConnection.released

    AORM::Spec.migrate_database @container

    PooledMockConnection.released.should eq released + 1
  end

  def test_closes_the_services_of_the_container_if_a_migration_fails : Nil
    App::Migrations::Version1.abort = true
    self.queue_database versions_table: false
    released = PooledMockConnection.released

    expect_raises AORM::Migrations::Exception::AbortMigration, "Aborted" do
      AORM::Spec.migrate_database @container
    end

    PooledMockConnection.released.should eq released + 1
  end

  def test_requires_migrations : Nil
    ASPEC::Methods.assert_compile_time_error "'AORM::Spec.migrate_database' requires the ORM bundle and migrations.", <<-'CR', preamble: %(require "./spec_helper.cr"\nrequire "../../src/spec")
      AORM::Spec.migrate_database
    CR
  end
end
