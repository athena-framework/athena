require "log/spec"
require "../spec_helper"
require "../../src/migrations"

module MigrationsSpec
  # Adds the SQL and parameters given to it.
  class Version1 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE a (id INTEGER)"
      self.add_sql "INSERT INTO a (id) VALUES (?)", [1]
    end

    def down : Nil
      self.add_sql "DROP TABLE a"
    end
  end

  class Version2 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE b (id INTEGER)"
    end
  end

  class Version3 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE c (id INTEGER)"
    end

    def down : Nil
      self.raise_irreversible_migration_exception
    end
  end
end

# Records executed migrations in memory.
class InMemoryMetadataStorage
  include AORM::Migrations::Metadata::Storage::Interface

  @executed = [] of AORM::Migrations::Metadata::ExecutedMigration

  def initialize; end

  def initialize(*executed_versions : AORM::Migrations::AbstractMigration.class)
    executed_versions.each do |migration_class|
      @executed << AORM::Migrations::Metadata::ExecutedMigration.new AORM::Migrations::Version.new(migration_class.name)
    end
  end

  def ensure_initialized : Nil
  end

  def executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList
    AORM::Migrations::Metadata::ExecutedMigrationsList.new @executed.sort_by(&.version.to_s)
  end

  def complete(result : AORM::Migrations::Version::ExecutionResult) : Nil
    if result.direction.down?
      @executed.reject! &.version.==(result.version)
    else
      @executed << AORM::Migrations::Metadata::ExecutedMigration.new result.version, result.executed_at, result.time
    end
  end

  def reset : Nil
    @executed.clear
  end
end

def migrations_spec_version(migration_class : AORM::Migrations::AbstractMigration.class) : AORM::Migrations::Version
  AORM::Migrations::Version.new migration_class.name
end

def migrations_spec_connection : AORM::Connection
  AORM::Connection.new MockConnection.new
end
