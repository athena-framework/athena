require "./spec_helper"

struct ExecuteCommandTest < ASPEC::TestCase
  @fixture : MigrationsCommandsFixture

  def initialize
    @fixture = MigrationsCommandsFixture.new
  end

  def test_executes_up_by_default : Nil
    tester = self.command_tester

    tester.execute(versions: ["MigrationsSpec::Version2"], interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain "[notice] Executing MigrationsSpec::Version2 up"
    tester.display.should contain "Successfully migrated version(s): MigrationsSpec::Version2: [UP]"
    @fixture.executed_versions.should eq ["MigrationsSpec::Version2"]
  end

  def test_executes_down : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1)
    tester = self.command_tester

    tester.execute(versions: ["MigrationsSpec::Version1"], "--down": true, interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain "Successfully migrated version(s): MigrationsSpec::Version1: [DOWN]"
    @fixture.executed_versions.should be_empty
  end

  def test_executes_multiple_versions : Nil
    self.command_tester.execute versions: ["MigrationsSpec::Version2", "MigrationsSpec::Version1"], interactive: false

    @fixture.executed_versions.should eq ["MigrationsSpec::Version1", "MigrationsSpec::Version2"]
  end

  def test_cancelling_the_confirmation : Nil
    tester = self.command_tester
    tester.inputs "no"

    tester.execute(versions: ["MigrationsSpec::Version1"]).should eq ACON::Command::Status::FAILURE

    tester.display.should contain "Migration cancelled!"
  end

  def test_dry_run : Nil
    self.command_tester.execute versions: ["MigrationsSpec::Version1"], "--dry-run": true

    @fixture.executed_versions.should be_empty
  end

  def test_unknown_version_raises : Nil
    expect_raises AORM::Migrations::Exception::MigrationClassNotFound, %(Migration class "Nope" was not found?) do
      self.command_tester.execute versions: ["Nope"], interactive: false
    end
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new AORM::Migrations::Commands::Execute.new(@fixture.storage, @fixture.plan_calculator, @fixture.migrator)
  end
end
