require "./spec_helper"

private struct ControlledMigration < AORM::Migrations::AbstractMigration
  def initialize(connection : AORM::Connection, @condition : Bool)
    super connection
  end

  def up : Nil
    self.warn_if @condition, "Something looks off"
    self.write "Doing the thing"
  end

  def skip : Nil
    self.skip_if @condition, "Nothing to do"
  end

  def abort : Nil
    self.abort_if @condition
  end

  def irreversible : Nil
    self.raise_irreversible_migration_exception "Data would be lost"
  end

  def typed_sql : Nil
    self.add_sql "UPDATE a SET b = ?, c = ?", [Time.utc(2026, 10, 14), 1], [AORM::Types::DATETIME] of String?
  end
end

struct AbstractMigrationTest < ASPEC::TestCase
  def test_defaults : Nil
    migration = MigrationsSpec::Version2.new migrations_spec_connection

    migration.transactional?.should be_true
    migration.description.should be_empty
    migration.sql.should be_empty
  end

  def test_add_sql_collects_statements_in_order : Nil
    migration = MigrationsSpec::Version1.new migrations_spec_connection
    migration.up

    migration.sql.map(&.statement).should eq ["CREATE TABLE a (id INTEGER)", "INSERT INTO a (id) VALUES (?)"]
    migration.sql[1].parameters.should eq [1] of DB::Any
  end

  def test_add_sql_keeps_parameter_types : Nil
    migration = ControlledMigration.new migrations_spec_connection, false
    migration.typed_sql

    migration.sql[0].parameters.should eq [Time.utc(2026, 10, 14), 1] of DB::Any
    migration.sql[0].types.should eq [AORM::Types::DATETIME] of String?
  end

  def test_add_sql_raises_once_frozen : Nil
    migration = MigrationsSpec::Version2.new migrations_spec_connection
    migration.freeze

    expect_raises AORM::Migrations::Exception::FrozenMigration, "The migration is frozen and cannot be edited anymore." do
      migration.up
    end
  end

  def test_down_aborts_by_default : Nil
    migration = MigrationsSpec::Version2.new migrations_spec_connection

    expect_raises AORM::Migrations::Exception::AbortMigration, %(No down() migration implemented for "MigrationsSpec::Version2") do
      migration.down
    end
  end

  def test_exceptions_can_be_rescued_via_the_namespace : Nil
    expect_raises AORM::Migrations::Exception, "Nothing to do" do
      ControlledMigration.new(migrations_spec_connection, true).skip
    end

    expect_raises AORM::Migrations::Exception::ControlException, "Unknown Reason" do
      ControlledMigration.new(migrations_spec_connection, true).abort
    end
  end

  def test_raise_irreversible_migration_exception : Nil
    expect_raises AORM::Migrations::Exception::IrreversibleMigration, "This migration is irreversible and cannot be reverted." do
      MigrationsSpec::Version3.new(migrations_spec_connection).down
    end

    expect_raises AORM::Migrations::Exception::IrreversibleMigration, "Data would be lost" do
      ControlledMigration.new(migrations_spec_connection, false).irreversible
    end
  end

  def test_skip_if : Nil
    ControlledMigration.new(migrations_spec_connection, false).skip

    expect_raises AORM::Migrations::Exception::SkipMigration, "Nothing to do" do
      ControlledMigration.new(migrations_spec_connection, true).skip
    end
  end

  def test_abort_if : Nil
    ControlledMigration.new(migrations_spec_connection, false).abort

    expect_raises AORM::Migrations::Exception::AbortMigration, "Unknown Reason" do
      ControlledMigration.new(migrations_spec_connection, true).abort
    end
  end

  def test_warn_if_and_write_log_with_the_migration : Nil
    Log.capture "athena.orm.migrations" do |logs|
      ControlledMigration.new(migrations_spec_connection, true).up

      logs.check :warn, "Something looks off"
      logs.entry.data[:migration].should eq "ControlledMigration"
      logs.next :notice, "Doing the thing"
      logs.empty
    end
  end

  def test_warn_if_does_not_log_when_false : Nil
    Log.capture "athena.orm.migrations" do |logs|
      ControlledMigration.new(migrations_spec_connection, false).up

      logs.check :notice, "Doing the thing"
      logs.empty
    end
  end
end
