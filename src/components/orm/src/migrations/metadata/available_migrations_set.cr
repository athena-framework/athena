# The unordered set of available migrations, as provided by `AORM::Migrations::MigrationsRepository#migrations`.
class Athena::ORM::Migrations::Metadata::AvailableMigrationsSet
  # Returns the migrations in the set.
  getter items : Array(AORM::Migrations::Metadata::AvailableMigration)

  def initialize(items : Enumerable(AORM::Migrations::Metadata::AvailableMigration))
    @items = items.to_a
  end

  # Returns the number of migrations in the set.
  def size : Int32
    @items.size
  end

  # Returns `true` if the set contains a migration with the provided *version*.
  def has_migration?(version : AORM::Migrations::Version) : Bool
    @items.any? &.version.==(version)
  end

  # Returns the migration with the provided *version*.
  #
  # Raises `AORM::Migrations::Exception::MigrationNotAvailable` if the set doesn't contain one.
  def migration(version : AORM::Migrations::Version) : AORM::Migrations::Metadata::AvailableMigration
    @items.find(&.version.==(version)) || raise AORM::Migrations::Exception::MigrationNotAvailable.new version
  end
end
