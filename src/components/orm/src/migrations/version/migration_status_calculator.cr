# Compares the available migrations with the executed ones.
class Athena::ORM::Migrations::Version::MigrationStatusCalculator
  def initialize(
    @migration_plan_calculator : AORM::Migrations::Version::MigrationPlanCalculator,
    @metadata_storage : AORM::Migrations::Metadata::Storage::Interface,
  ); end

  # Returns the executed migrations that aren't available, such as ones whose type was removed.
  def executed_unavailable_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList
    @metadata_storage.executed_migrations.unavailable_subset @migration_plan_calculator.migrations
  end

  # Returns the available migrations that haven't been executed, ordered by version.
  def new_migrations : AORM::Migrations::Metadata::AvailableMigrationsList
    @migration_plan_calculator.migrations.new_subset @metadata_storage.executed_migrations
  end
end
