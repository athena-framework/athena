# The available migrations, ordered by version.
class Athena::ORM::Migrations::Metadata::AvailableMigrationsList
  # Returns the migrations in the list.
  getter items : Array(AORM::Migrations::Metadata::AvailableMigration)

  def initialize(items : Enumerable(AORM::Migrations::Metadata::AvailableMigration))
    @items = items.to_a
  end

  # Returns the migration at *offset* from the start of the list.
  #
  # Raises `AORM::Migrations::Exception::NoMigrationsFoundWithCriteria` if there isn't one.
  def first(offset : Int32 = 0) : AORM::Migrations::Metadata::AvailableMigration
    @items[offset]? || raise AORM::Migrations::Exception::NoMigrationsFoundWithCriteria.new "first#{offset > 0 ? "+#{offset}" : ""}"
  end

  # Returns the last migration of the list, or the one *offset* before it when *offset* is negative.
  #
  # Raises `AORM::Migrations::Exception::NoMigrationsFoundWithCriteria` if there isn't one.
  def last(offset : Int32 = 0) : AORM::Migrations::Metadata::AvailableMigration
    offset = @items.size - 1 + offset

    (@items[offset]? if offset >= 0) || raise AORM::Migrations::Exception::NoMigrationsFoundWithCriteria.new "last#{offset > 0 ? "+#{offset}" : ""}"
  end

  # Returns the number of migrations in the list.
  def size : Int32
    @items.size
  end

  # Returns `true` if the list contains a migration with the provided *version*.
  def has_migration?(version : AORM::Migrations::Version::Version) : Bool
    @items.any? &.version.==(version)
  end

  # Returns the migration with the provided *version*.
  #
  # Raises `AORM::Migrations::Exception::MigrationNotAvailable` if the list doesn't contain one.
  def migration(version : AORM::Migrations::Version::Version) : AORM::Migrations::Metadata::AvailableMigration
    @items.find(&.version.==(version)) || raise AORM::Migrations::Exception::MigrationNotAvailable.new version
  end

  # Returns the migrations of this list that aren't in *executed_migrations*.
  def new_subset(executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList) : self
    self.class.new @items.reject { |migration| executed_migrations.has_migration? migration.version }
  end
end
