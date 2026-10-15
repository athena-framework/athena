require "../spec_helper"

struct MigrationStatusCalculatorTest < ASPEC::TestCase
  def test_new_and_executed_unavailable_migrations : Nil
    storage = InMemoryMetadataStorage.new MigrationsSpec::Version1, MigrationsSpec::Version3
    repository = AORM::Migrations::MigrationsRepository.new [MigrationsSpec::Version1, MigrationsSpec::Version2] of AORM::Migrations::AbstractMigration.class
    calculator = AORM::Migrations::Version::MigrationStatusCalculator.new AORM::Migrations::Version::MigrationPlanCalculator.new(repository, storage), storage

    calculator.new_migrations.items.map(&.migration_class).should eq [MigrationsSpec::Version2]
    calculator.executed_unavailable_migrations.items.map(&.version.to_s).should eq ["MigrationsSpec::Version3"]
  end
end
