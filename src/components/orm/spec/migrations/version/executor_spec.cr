require "../spec_helper"

private class ExecutorSpecMigration < AORM::Migrations::AbstractMigration
  class_property calls = [] of String
  class_property? skip = false
  class_property? error = false
  class_property? transactional_migration = true
  class_property description_text = ""

  def self.reset : Nil
    @@calls = [] of String
    @@skip = @@error = false
    @@transactional_migration = true
    @@description_text = ""
  end

  def description : String
    @@description_text
  end

  def transactional? : Bool
    @@transactional_migration
  end

  def pre_up : Nil
    @@calls << "pre_up"
  end

  def post_up : Nil
    @@calls << "post_up"
  end

  def pre_down : Nil
    @@calls << "pre_down"
  end

  def post_down : Nil
    @@calls << "post_down"
  end

  def up : Nil
    self.skip_if @@skip, "Not needed"
    raise "Migration error" if @@error

    self.add_sql "SELECT 1", [1], [AORM::Types::INTEGER] of String?
    self.add_sql "SELECT 2"
  end

  def down : Nil
    self.add_sql "SELECT 3", [5], [AORM::Types::INTEGER] of String?
    self.add_sql "SELECT 4", [6], [AORM::Types::INTEGER] of String?
  end
end

private class EmptySpecMigration < AORM::Migrations::AbstractMigration
  def up : Nil
  end
end

# Also provides the SQL to record a migration, like `AORM::Migrations::Metadata::Storage::TableMetadataStorage`.
private class DryRunMetadataStorage < InMemoryMetadataStorage
  def sql(result : AORM::Migrations::Version::ExecutionResult) : Array(AORM::Migrations::Query::Query)
    [AORM::Migrations::Query::Query.new "INSERT INTO athena_orm_migration_versions (version) VALUES ('#{result.version}')"]
  end
end

private class FailingMetadataStorage < InMemoryMetadataStorage
  def complete(result : AORM::Migrations::Version::ExecutionResult) : Nil
    raise "Storage error"
  end
end

struct ExecutorTest < ASPEC::TestCase
  @wrapped : MockConnection
  @storage : InMemoryMetadataStorage

  def initialize
    ExecutorSpecMigration.reset

    @wrapped = MockConnection.new
    @storage = InMemoryMetadataStorage.new
  end

  def test_add_sql : Nil
    executor = self.executor
    query = AORM::Migrations::Query::Query.new "SELECT 1", [1] of DB::Any, [AORM::Types::INTEGER] of String?

    executor.add_sql query

    executor.sql.should eq [query]
  end

  def test_execute_with_no_queries : Nil
    Log.capture "athena.orm.migrations" do |logs|
      result = self.executor.execute self.plan(EmptySpecMigration, :up), AORM::Migrations::MigratorConfiguration.new

      result.sql.should be_empty
      result.time.should_not be_nil
      result.state.should eq AORM::Migrations::Version::State::NONE

      logs.check :info, "++ migrating #{EmptySpecMigration}"
      logs.next :warn, "Migration #{EmptySpecMigration} was executed but did not result in any SQL statements."
      logs.next :info, /^Migration #{EmptySpecMigration} migrated \(took \d+ms\)$/
      logs.empty
    end
  end

  def test_execute_up : Nil
    plan = self.plan ExecutorSpecMigration, :up

    Log.capture "athena.orm.migrations" do |logs|
      result = self.executor.execute plan, AORM::Migrations::MigratorConfiguration.new(time_all_queries: true)

      result.sql.map(&.statement).should eq ["SELECT 1", "SELECT 2"]
      result.sql[0].parameters.should eq [1] of DB::Any
      result.sql[0].types.should eq [AORM::Types::INTEGER] of String?
      result.time.should_not be_nil
      result.executed_at.should_not be_nil
      result.state.should eq AORM::Migrations::Version::State::NONE
      plan.result.should be result
      ExecutorSpecMigration.calls.should eq ["pre_up", "post_up"]

      logs.check :info, "++ migrating #{ExecutorSpecMigration}"
      logs.next :notice, "SELECT 1 with parameters ([1])"
      logs.next :notice, /^Query took \d+ms$/
      logs.next :notice, "SELECT 2 "
      logs.next :notice, /^Query took \d+ms$/
      logs.next :info, /^Migration #{ExecutorSpecMigration} migrated \(took \d+ms\)$/
      logs.empty
    end

    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "SELECT 1", "SELECT 2", "COMMIT"]
    @storage.executed_migrations.items.map(&.version).should eq [plan.version]
  end

  def test_execute_up_appends_the_description : Nil
    ExecutorSpecMigration.description_text = "testing"

    Log.capture "athena.orm.migrations" do |logs|
      self.executor.execute self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new

      logs.check :info, "++ migrating #{ExecutorSpecMigration} (testing)"
    end
  end

  def test_execute_down : Nil
    @storage.complete AORM::Migrations::Version::ExecutionResult.new(migrations_spec_version(ExecutorSpecMigration))

    Log.capture "athena.orm.migrations" do |logs|
      result = self.executor.execute self.plan(ExecutorSpecMigration, :down), AORM::Migrations::MigratorConfiguration.new(time_all_queries: true)

      result.sql.map(&.statement).should eq ["SELECT 3", "SELECT 4"]
      result.sql.map(&.parameters).should eq [[5] of DB::Any, [6] of DB::Any]
      result.state.should eq AORM::Migrations::Version::State::NONE
      ExecutorSpecMigration.calls.should eq ["pre_down", "post_down"]

      logs.check :info, "++ reverting #{ExecutorSpecMigration}"
      logs.next :notice, "SELECT 3 with parameters ([5])"
      logs.next :notice, /^Query took \d+ms$/
      logs.next :notice, "SELECT 4 with parameters ([6])"
      logs.next :notice, /^Query took \d+ms$/
      logs.next :info, /^Migration #{ExecutorSpecMigration} reverted \(took \d+ms\)$/
      logs.empty
    end

    @storage.executed_migrations.size.should eq 0
  end

  def test_queries_are_logged_at_debug_level_unless_timed : Nil
    Log.capture "athena.orm.migrations" do |logs|
      self.executor.execute self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new

      logs.check :debug, "SELECT 1 with parameters ([1])"
      logs.next :debug, "SELECT 2 "
    end
  end

  def test_execute_dry_run : Nil
    storage = DryRunMetadataStorage.new

    Log.capture "athena.orm.migrations" do |logs|
      result = self.executor(storage).execute self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new(dry_run: true, time_all_queries: true)

      result.sql.map(&.statement).should eq [
        "SELECT 1",
        "SELECT 2",
        "INSERT INTO athena_orm_migration_versions (version) VALUES ('#{ExecutorSpecMigration}')",
      ]
      result.state.should eq AORM::Migrations::Version::State::NONE
      ExecutorSpecMigration.calls.should eq ["pre_up", "post_up"]

      logs.check :info, "++ migrating #{ExecutorSpecMigration}"
      logs.next :notice, "SELECT 1 with parameters ([1])"
      logs.next :notice, "SELECT 2 "
      logs.next :info, /^Migration #{ExecutorSpecMigration} migrated \(took \d+ms\)$/
      logs.empty
    end

    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "COMMIT"]
    storage.executed_migrations.size.should eq 0
  end

  def test_skip_migration : Nil
    ExecutorSpecMigration.skip = true
    plan = self.plan ExecutorSpecMigration, :up

    Log.capture "athena.orm.migrations" do |logs|
      result = self.executor.execute plan, AORM::Migrations::MigratorConfiguration.new

      result.skipped?.should be_true
      result.sql.should be_empty
      result.state.should eq AORM::Migrations::Version::State::EXEC
      plan.result.should be result
      ExecutorSpecMigration.calls.should eq ["pre_up"]

      logs.check :notice, %(Migration #{ExecutorSpecMigration} skipped during Execution. Reason: "Not needed")
    end

    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "ROLLBACK"]
    @storage.executed_migrations.size.should eq 0
  end

  def test_error_migration : Nil
    ExecutorSpecMigration.error = true
    plan = self.plan ExecutorSpecMigration, :up

    Log.capture "athena.orm.migrations" do |logs|
      expect_raises Exception, "Migration error" do
        self.executor.execute plan, AORM::Migrations::MigratorConfiguration.new
      end

      logs.check :error, %(Migration #{ExecutorSpecMigration} failed during Execution. Error: "Migration error")
    end

    result = plan.result.should_not be_nil
    result.error?.should be_true
    result.exception.try(&.message).should eq "Migration error"
    result.sql.should be_empty
    result.state.should eq AORM::Migrations::Version::State::EXEC
    ExecutorSpecMigration.calls.should eq ["pre_up"]
    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "ROLLBACK"]
  end

  def test_changes_are_not_committed_if_the_metadata_storage_fails : Nil
    plan = self.plan ExecutorSpecMigration, :up

    expect_raises Exception, "Storage error" do
      self.executor(FailingMetadataStorage.new).execute plan, AORM::Migrations::MigratorConfiguration.new
    end

    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "SELECT 1", "SELECT 2", "ROLLBACK"]
    plan.result.should_not be_nil
  end

  def test_non_transactional_migration_does_not_use_a_transaction : Nil
    ExecutorSpecMigration.transactional_migration = false

    self.executor.execute self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new

    @wrapped.executed_statements.map(&.[0]).should eq ["SELECT 1", "SELECT 2"]
  end

  def test_each_execution_uses_a_new_migration_instance : Nil
    executor = self.executor

    executor.execute(self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new).sql.size.should eq 2
    executor.execute(self.plan(ExecutorSpecMigration, :up), AORM::Migrations::MigratorConfiguration.new).sql.size.should eq 2
  end

  private def executor(storage : InMemoryMetadataStorage = @storage) : AORM::Migrations::Version::Executor
    AORM::Migrations::Version::Executor.new storage, AORM::Connection.new(@wrapped)
  end

  private def plan(migration_class : AORM::Migrations::AbstractMigration.class, direction : AORM::Migrations::Version::Direction) : AORM::Migrations::Metadata::MigrationPlan
    AORM::Migrations::Metadata::MigrationPlan.new migrations_spec_version(migration_class), migration_class, direction
  end
end
