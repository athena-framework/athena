require "./spec_helper"

struct VersionCommandTest < ASPEC::TestCase
  @fixture : MigrationsCommandsFixture

  def initialize
    @fixture = MigrationsCommandsFixture.new
  end

  def test_add : Nil
    tester = self.command_tester

    tester.execute(version: "MigrationsSpec::Version2", "--add": true, interactive: false).should eq ACON::Command::Status::SUCCESS

    tester.display.should contain "MigrationsSpec::Version2 added to the version table."
    @fixture.executed_versions.should eq ["MigrationsSpec::Version2"]
    @fixture.wrapped.executed_statements.should be_empty
  end

  def test_delete : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1)
    tester = self.command_tester

    tester.execute version: "MigrationsSpec::Version1", "--delete": true, interactive: false

    tester.display.should contain "MigrationsSpec::Version1 deleted from the version table."
    @fixture.executed_versions.should be_empty
  end

  def test_add_all : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version2)

    self.command_tester.execute "--add": true, "--all": true, interactive: false

    @fixture.executed_versions.should eq ["MigrationsSpec::Version1", "MigrationsSpec::Version2", "MigrationsSpec::Version3"]
  end

  def test_delete_all : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1, MigrationsSpec::Version3)

    self.command_tester.execute "--delete": true, "--all": true, interactive: false

    @fixture.executed_versions.should be_empty
  end

  def test_add_range : Nil
    self.command_tester.execute "--add": true, "--range-from": "MigrationsSpec::Version2", "--range-to": "MigrationsSpec::Version3", interactive: false

    @fixture.executed_versions.should eq ["MigrationsSpec::Version2", "MigrationsSpec::Version3"]
  end

  def test_adding_an_executed_version_raises : Nil
    @fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1)

    expect_raises AORM::Migrations::Exception::VersionAlreadyExists, %(The version "MigrationsSpec::Version1" already exists in the version table.) do
      self.command_tester.execute version: "MigrationsSpec::Version1", "--add": true, interactive: false
    end
  end

  def test_deleting_a_version_that_was_not_executed_raises : Nil
    expect_raises AORM::Migrations::Exception::VersionDoesNotExist, %(The version "MigrationsSpec::Version1" does not exist in the version table.) do
      self.command_tester.execute version: "MigrationsSpec::Version1", "--delete": true, interactive: false
    end
  end

  def test_adding_an_unknown_version_raises : Nil
    expect_raises AORM::Migrations::Exception::UnknownMigrationVersion, "Could not find migration version Nope" do
      self.command_tester.execute version: "Nope", "--add": true, interactive: false
    end
  end

  def test_deleting_an_unavailable_version_asks_to_confirm : Nil
    storage = InMemoryMetadataStorage.new
    storage.complete AORM::Migrations::Version::ExecutionResult.new(AORM::Migrations::Version.new("MigrationsSpec::Removed"), :up)
    @fixture = MigrationsCommandsFixture.new storage: storage
    tester = self.command_tester
    tester.inputs "yes", "yes"

    tester.execute version: "MigrationsSpec::Removed", "--delete": true

    tester.display.should contain "MigrationsSpec::Removed deleted from the version table."
    @fixture.executed_versions.should be_empty
  end

  def test_cancelling_the_confirmation : Nil
    tester = self.command_tester
    tester.inputs "no"

    tester.execute version: "MigrationsSpec::Version1", "--add": true

    tester.display.should contain "Migration cancelled!"
    @fixture.executed_versions.should be_empty
  end

  @[DataProvider("invalid_options_provider")]
  def test_invalid_options(input : Hash(String, String | Bool), message : String) : Nil
    expect_raises AORM::Migrations::Exception::InvalidOptionUsage, message do
      self.command_tester.execute input, interactive: false
    end
  end

  def invalid_options_provider : Tuple
    {
      { {"version" => "MigrationsSpec::Version1"} of String => String | Bool, "You must specify whether you want to --add or --delete the specified version." },
      { {"--add" => true, "--all" => true, "--range-from" => "MigrationsSpec::Version1"} of String => String | Bool, "Options --all and --range-to/--range-from both used. You should use only one of them." },
      { {"--add" => true, "--range-from" => "MigrationsSpec::Version1"} of String => String | Bool, "Options --range-to and --range-from should be used together." },
      { {"--add" => true} of String => String | Bool, "You must specify the version or use the --all argument." },
    }
  end

  private def command_tester : ACON::Spec::CommandTester
    ACON::Spec::CommandTester.new AORM::Migrations::Commands::Version.new(@fixture.storage, @fixture.repository, @fixture.plan_calculator)
  end
end
