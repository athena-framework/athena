require "./spec_helper"

struct StatusCommandTest < ASPEC::TestCase
  def test_shows_the_configuration_and_versions : Nil
    fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1)
    tester = ACON::Spec::CommandTester.new AORM::Migrations::Commands::Status.new(fixture.status_infos_helper)

    tester.execute.should eq ACON::Command::Status::SUCCESS

    display = tester.display
    display.should contain "| Configuration"
    display.should match /\| Storage\s+\| Type\s+\| Athena::ORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration/
    display.should match /\|\s+\| Table Name\s+\| athena_orm_migration_versions/
    display.should match /\| Database\s+\| Driver\s+\| Athena::ORM::Driver::SQLite3/
    display.should match /\| Versions\s+\| Previous\s+\| 0/
    display.should match /\|\s+\| Current\s+\| MigrationsSpec::Version1/
    display.should match /\|\s+\| Next\s+\| MigrationsSpec::Version2/
    display.should match /\|\s+\| Latest\s+\| MigrationsSpec::Version3/
    display.should match /\| Migrations\s+\| Executed\s+\| 1/
    display.should match /\|\s+\| New\s+\| 2/
    display.should match /\| Migration Namespaces \| MigrationsSpec\s+\| src\/migrations/
  end

  def test_next_when_every_migration_is_executed : Nil
    fixture = MigrationsCommandsFixture.new storage: InMemoryMetadataStorage.new(MigrationsSpec::Version1, MigrationsSpec::Version2, MigrationsSpec::Version3)
    tester = ACON::Spec::CommandTester.new AORM::Migrations::Commands::Status.new(fixture.status_infos_helper)

    tester.execute

    tester.display.should match /\|\s+\| Next\s+\| Already at latest version/
  end
end

struct ListCommandTest < ASPEC::TestCase
  def test_lists_available_and_executed_migrations : Nil
    storage = InMemoryMetadataStorage.new
    storage.complete AORM::Migrations::Version::ExecutionResult.new(migrations_spec_version(MigrationsSpec::Version1), :up, Time.utc(2026, 10, 14, 12, 30)).tap(&.time = 1.5.seconds)
    storage.complete AORM::Migrations::Version::ExecutionResult.new(AORM::Migrations::Version.new("MigrationsSpec::Removed"), :up)

    fixture = MigrationsCommandsFixture.new [MigrationsSpec::Version1, MigrationsSpec::Version2] of AORM::Migrations::AbstractMigration.class, storage
    tester = ACON::Spec::CommandTester.new AORM::Migrations::Commands::List.new(fixture.plan_calculator, fixture.storage, fixture.status_infos_helper)

    tester.execute.should eq ACON::Command::Status::SUCCESS

    display = tester.display
    display.should match /\| MigrationsSpec::Removed\s+\| migrated, not available\s+\|/
    display.should match /\| MigrationsSpec::Version1\s+\| migrated\s+\| 2026-10-14 12:30:00 \| 1\.5s\s+\|/
    display.should match /\| MigrationsSpec::Version2\s+\| not migrated\s+\|/
    display.index!("MigrationsSpec::Removed").should be < display.index!("MigrationsSpec::Version1")
  end
end
