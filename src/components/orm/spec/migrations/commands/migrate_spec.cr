require "./spec_helper"

struct MigrateCommandTest < ASPEC::TestCase
  @fixture : MigrationsCommandsFixture

  def initialize
    @fixture = MigrationsCommandsFixture.new
  end

  def test_migrates_to_the_latest_version : Nil
    tester = self.command_tester

    tester.execute(interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain "[notice] Migrating up to MigrationsSpec::Version3"
    tester.display.should contain "[OK] Successfully migrated to version: MigrationsSpec::Version3"
    @fixture.executed_versions.should eq ["MigrationsSpec::Version1", "MigrationsSpec::Version2", "MigrationsSpec::Version3"]
  end

  def test_migrates_to_an_alias : Nil
    self.command_tester.execute version: "next", interactive: false

    @fixture.executed_versions.should eq ["MigrationsSpec::Version1"]
  end

  def test_already_at_the_latest_version : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1, MigrationsSpec::Version2, MigrationsSpec::Version3)
    tester = self.command_tester

    tester.execute(interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain %(Already at the latest version ("MigrationsSpec::Version3"))
  end

  def test_unreachable_alias : Nil
    tester = self.command_tester

    tester.execute(version: "prev", interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain %(The version "prev" couldn't be reached, you are at version "0")
  end

  @[DataProvider("target_aliases")]
  def test_execute_at_version(target_alias : String, level : String, executed_migration : String?) : Nil
    storage = executed_migration ? InMemoryMetadataStorage.new(MigrationsSpec::Version1) : InMemoryMetadataStorage.new
    @fixture = MigrationsCommandsFixture.new [MigrationsSpec::Version1] of AORM::Migrations::AbstractMigration.class, storage
    tester = self.command_tester

    tester.execute(version: target_alias, interactive: false).should eq ACON::Command::Status::SUCCESS

    message = if target_alias.in? "current", "latest", "first"
                %([#{level}] Already at the #{target_alias} version ("#{executed_migration || "0"}"))
              elsif target_alias == "MigrationsSpec::Version1"
                %([#{level}] You are already at version "#{target_alias}")
              else
                %([#{level}] The version "#{target_alias}" couldn't be reached, you are at version "#{executed_migration || "0"}")
              end

    # Long messages wrap onto several lines of the output.
    tester.display.should match Regex.new(message.split(' ').join("\\s+") { |word| Regex.escape word })
  end

  def target_aliases : Tuple
    {
      {"MigrationsSpec::Version1", "OK", "MigrationsSpec::Version1"}, # already at the migration
      {"latest", "OK", "MigrationsSpec::Version1"},                   # already at latest
      {"first", "OK", nil},                                           # already at first
      {"next", "ERROR", "MigrationsSpec::Version1"},                  # already at latest, no next available
      {"prev", "ERROR", nil},                                         # no prev, already at first
      {"current", "OK", "MigrationsSpec::Version1"},                  # already at latest, always
      {"current+1", "ERROR", "MigrationsSpec::Version1"},             # no current+1
    }
  end

  def test_unknown_version : Nil
    tester = self.command_tester

    tester.execute(version: "nope", interactive: false).should eq ACON::Command::Status::FAILURE

    tester.display.should contain "Unknown version: nope"
  end

  def test_cancelling_the_confirmation : Nil
    tester = self.command_tester
    tester.inputs "no"

    tester.execute.should eq ACON::Command::Status.new 3

    tester.display.should contain "Migration cancelled!"
    @fixture.executed_versions.should be_empty
  end

  def test_confirming : Nil
    tester = self.command_tester
    tester.inputs "yes"

    tester.execute.should eq ACON::Command::Status::SUCCESS

    @fixture.executed_versions.size.should eq 3
  end

  def test_dry_run_does_not_ask_or_record : Nil
    tester = self.command_tester

    tester.execute("--dry-run": true).should eq ACON::Command::Status::SUCCESS

    tester.display.should_not contain "WARNING!"
    tester.display.should contain "[notice] Migrating (dry-run) up to MigrationsSpec::Version3"
    @fixture.executed_versions.should be_empty
    @fixture.wrapped.executed_statements.map(&.[0]).uniq!.should eq ["BEGIN", "COMMIT"]
  end

  def test_without_registered_migrations : Nil
    @fixture = MigrationsCommandsFixture.new [] of AORM::Migrations::AbstractMigration.class
    tester = self.command_tester

    tester.execute(interactive: false).should eq ACON::Command::Status::FAILURE
    tester.display.should match /\[ERROR\] The version "latest" couldn't be reached, there are no registered\s+migrations\./

    tester.execute("--allow-no-migration": true, interactive: false).should eq ACON::Command::Status::SUCCESS
    tester.display.should match /\[WARNING\] The version "latest" couldn't be reached, there are no registered\s+migrations\./
  end

  def test_executed_unavailable_migrations_ask_to_continue : Nil
    @fixture = MigrationsCommandsFixture.new [MigrationsSpec::Version2] of AORM::Migrations::AbstractMigration.class, InMemoryMetadataStorage.new(MigrationsSpec::Version1)
    tester = self.command_tester
    tester.inputs "yes", "no"

    tester.execute.should eq ACON::Command::Status.new 3

    tester.display.should match /You have 1 previously executed migrations in the database that are\s+not registered migrations\./
    tester.display.should contain "(MigrationsSpec::Version1)"
    tester.display.should contain "Migration cancelled!"
  end

  def test_queries_are_shown_when_very_verbose : Nil
    tester = self.command_tester

    tester.execute version: "next", interactive: false, verbosity: :very_verbose

    tester.display.should contain "[info] ++ migrating MigrationsSpec::Version1"
    tester.display.should contain "[debug] CREATE TABLE a (id INTEGER)"
    tester.display.should contain "[debug] INSERT INTO a (id) VALUES (?) with parameters ([1])"
  end

  def test_the_log_is_restored_after_running : Nil
    backend = AORM::Migrations::Log.backend
    level = AORM::Migrations::Log.level
    changed_level = AORM::Migrations::Log.changed_level

    self.command_tester.execute interactive: false, verbosity: :very_verbose

    AORM::Migrations::Log.backend.should be backend
    AORM::Migrations::Log.level.should eq level
    AORM::Migrations::Log.changed_level.should eq changed_level
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new AORM::Migrations::Commands::Migrate.new(
      @fixture.storage,
      @fixture.repository,
      @fixture.alias_resolver,
      @fixture.plan_calculator,
      @fixture.status_calculator,
      @fixture.migrator,
    )
  end
end
