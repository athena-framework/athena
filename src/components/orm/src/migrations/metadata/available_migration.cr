# A migration that can be executed, as provided by `AORM::Migrations::MigrationsRepository`.
struct Athena::ORM::Migrations::Metadata::AvailableMigration
  # Returns the version of the migration.
  getter version : AORM::Migrations::Version::Version

  # Returns the type of the migration.
  # A new instance of it is created each time the migration is executed.
  getter migration_class : AORM::Migrations::AbstractMigration.class

  def initialize(
    @version : AORM::Migrations::Version::Version,
    @migration_class : AORM::Migrations::AbstractMigration.class,
  ); end
end
