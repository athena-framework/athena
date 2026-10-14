# Provides the migrations that can be executed, keyed by their version.
#
# ```
# repository = AORM::Migrations::MigrationsRepository.new [
#   App::Migrations::Version20261014120000,
#   App::Migrations::Version20261015090000,
# ] of AORM::Migrations::AbstractMigration.class
#
# repository.has_migration? AORM::Migrations::Version::Version.new("App::Migrations::Version20261014120000") # => true
# ```
class Athena::ORM::Migrations::MigrationsRepository
  @migrations = Hash(AORM::Migrations::Version::Version, AORM::Migrations::Metadata::AvailableMigration).new

  # Raises `AORM::Migrations::Exception::DuplicateMigrationVersion` if *migration_classes* contains the same type more than once.
  def initialize(migration_classes : Enumerable(AORM::Migrations::AbstractMigration.class))
    migration_classes.each do |migration_class|
      self.register_migration migration_class
    end
  end

  # Returns `true` if there is a migration with the provided *version*.
  def has_migration?(version : AORM::Migrations::Version::Version) : Bool
    @migrations.has_key? version
  end

  # Returns the migration with the provided *version*.
  #
  # Raises `AORM::Migrations::Exception::MigrationClassNotFound` if there isn't one.
  def migration(version : AORM::Migrations::Version::Version) : AORM::Migrations::Metadata::AvailableMigration
    @migrations[version]? || raise AORM::Migrations::Exception::MigrationClassNotFound.new version.to_s
  end

  # Returns all the migrations.
  def migrations : AORM::Migrations::Metadata::AvailableMigrationsSet
    AORM::Migrations::Metadata::AvailableMigrationsSet.new @migrations.values
  end

  private def register_migration(migration_class : AORM::Migrations::AbstractMigration.class) : Nil
    version = AORM::Migrations::Version::Version.new migration_class.name

    if @migrations.has_key? version
      raise AORM::Migrations::Exception::DuplicateMigrationVersion.new version.to_s, version.to_s
    end

    @migrations[version] = AORM::Migrations::Metadata::AvailableMigration.new version, migration_class
  end
end
