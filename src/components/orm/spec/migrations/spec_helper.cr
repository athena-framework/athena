require "log/spec"
require "../spec_helper"
require "../../src/migrations"

module MigrationsSpec
  # Adds the SQL and parameters given to it.
  struct Version1 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE a (id INTEGER)"
      self.add_sql "INSERT INTO a (id) VALUES (?)", [1]
    end

    def down : Nil
      self.add_sql "DROP TABLE a"
    end
  end

  struct Version2 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE b (id INTEGER)"
    end
  end

  struct Version3 < AORM::Migrations::AbstractMigration
    def up : Nil
      self.add_sql "CREATE TABLE c (id INTEGER)"
    end

    def down : Nil
      self.raise_irreversible_migration_exception
    end
  end
end

def migrations_spec_connection : AORM::Connection
  AORM::Connection.new MockConnection.new
end
