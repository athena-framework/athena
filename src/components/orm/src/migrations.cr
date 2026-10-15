require "./athena-orm"

# Types nesting others are required first, so that they aren't defined as modules by the nested types.
require "./migrations/configuration/configuration"
require "./migrations/generator/generator"
require "./migrations/query/query"
require "./migrations/version/version"

require "./migrations/exception/*"
require "./migrations/generator/*"
require "./migrations/metadata/*"
require "./migrations/metadata/storage/*"
require "./migrations/version/*"

require "./migrations/abstract_migration"
require "./migrations/migrations_repository"
require "./migrations/migrator"
require "./migrations/migrator_configuration"

# The commands are only defined when the console component is required, before or after this file.
macro finished
  {% if @top_level.has_constant? "ACON" %}
    require "./migrations/commands/abstract_command"
    require "./migrations/commands/*"
  {% end %}
end

# Versions a database's schema through migrations, each a type that applies one change, and reverts it.
#
# Require `athena-orm/migrations` to use them:
#
# ```
# require "athena-orm/migrations"
#
# class App::Migrations::Version20261014120000 < AORM::Migrations::AbstractMigration
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
# See the [migrations guide](/ORM/database_migrations/) for how to configure, generate and execute them.
module Athena::ORM::Migrations
  # Messages a migration writes via `AbstractMigration#write`, and warnings it raises via `AbstractMigration#warn_if`, are logged here.
  Log = ::Log.for "athena.orm.migrations"

  # Both acts as a namespace for exceptions related to migrations, as well as a way to check for exceptions from them.
  module Exception; end

  # Contains the types describing which migrations are available, which have been executed, and which are planned to be.
  module Metadata; end
end
