require "./athena-orm"

require "./migrations/exception/*"
require "./migrations/metadata/*"
require "./migrations/metadata/storage/*"
require "./migrations/query/*"
require "./migrations/version/*"

require "./migrations/abstract_migration"
require "./migrations/migrations_repository"

# Versions a database's schema through migrations, each a type that applies one change, and reverts it.
#
# Require `athena-orm/migrations` to use them:
#
# ```
# require "athena-orm/migrations"
#
# struct App::Migrations::Version20261014120000 < AORM::Migrations::AbstractMigration
#   def description : String
#     "Create the users table"
#   end
#
#   def up : Nil
#     self.add_sql "CREATE TABLE users (id BIGINT NOT NULL, name VARCHAR(255) NOT NULL, PRIMARY KEY (id))"
#   end
#
#   def down : Nil
#     self.add_sql "DROP TABLE users"
#   end
# end
# ```
#
# The version of a migration is the fully qualified name of its type, and migrations run in the order of their versions.
module Athena::ORM::Migrations
  # Messages a migration writes via `AbstractMigration#write`, and warnings it raises via `AbstractMigration#warn_if`, are logged here.
  Log = ::Log.for "athena.orm.migrations"

  # Both acts as a namespace for exceptions related to migrations, as well as a way to check for exceptions from them.
  module Exception; end

  # Contains the types describing which migrations are available, which have been executed, and which are planned to be.
  module Metadata; end

  # Contains the SQL statements migrations execute, see `AbstractMigration#add_sql`.
  module Query; end

  # Contains the types describing the versions of migrations and the result of executing one.
  module Version; end
end
