require "./spec_helper"

struct MigratorTest < ASPEC::TestCase
  @wrapped : MockConnection
  @migrator : AORM::Migrations::Migrator

  def initialize
    @wrapped = MockConnection.new
    @migrator = AORM::Migrations::Migrator.new AORM::Migrations::Version::Executor.new(InMemoryMetadataStorage.new, AORM::Connection.new(@wrapped))
  end

  def test_empty_plan : Nil
    Log.capture "athena.orm.migrations" do |logs|
      @migrator.migrate(self.plan_list, AORM::Migrations::MigratorConfiguration.new).should be_empty

      logs.check :notice, "No migrations to execute."
    end
  end

  def test_migrate_returns_the_sql_of_each_migration : Nil
    Log.capture "athena.orm.migrations" do |logs|
      sql = @migrator.migrate self.plan_list(MigrationsSpec::Version1, MigrationsSpec::Version2), AORM::Migrations::MigratorConfiguration.new

      sql.keys.should eq [migrations_spec_version(MigrationsSpec::Version1), migrations_spec_version(MigrationsSpec::Version2)]
      sql[migrations_spec_version(MigrationsSpec::Version1)].map(&.statement).should eq ["CREATE TABLE a (id INTEGER)", "INSERT INTO a (id) VALUES (?)"]
      sql[migrations_spec_version(MigrationsSpec::Version2)].map(&.statement).should eq ["CREATE TABLE b (id INTEGER)"]

      logs.check :notice, /^finished in \d+ms, 2 migrations executed, 3 sql queries$/
      logs.empty
    end
  end

  def test_migrate_stops_at_the_first_failure : Nil
    expect_raises AORM::Migrations::Exception::IrreversibleMigration do
      @migrator.migrate self.plan_list(MigrationsSpec::Version3, MigrationsSpec::Version1, direction: :down), AORM::Migrations::MigratorConfiguration.new
    end

    @wrapped.executed_statements.map(&.[0]).should eq ["BEGIN", "ROLLBACK"]
  end

  private def plan_list(*migration_classes : AORM::Migrations::AbstractMigration.class, direction : AORM::Migrations::Version::Direction = :up) : AORM::Migrations::Metadata::MigrationPlanList
    AORM::Migrations::Metadata::MigrationPlanList.new(
      migration_classes.map { |migration_class| AORM::Migrations::Metadata::MigrationPlan.new migrations_spec_version(migration_class), migration_class, direction }.to_a,
      direction
    )
  end

  private def plan_list : AORM::Migrations::Metadata::MigrationPlanList
    AORM::Migrations::Metadata::MigrationPlanList.new [] of AORM::Migrations::Metadata::MigrationPlan, :up
  end
end
