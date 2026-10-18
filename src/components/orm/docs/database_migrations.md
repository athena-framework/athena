As an application evolves, so does its database's schema: tables are added, columns change, and data moves between them.
Migrations version those changes, so that every database the application runs on, from a development machine to production, is brought up to date, or rolled back, the same way.

Each migration is a Crystal type that applies one change in its `#up` method and reverts it in its `#down` method, by adding the SQL to execute.
The migrations that have been executed are recorded in a table of the database, so that each one is only executed once.

## Installation

Migrations come with the ORM, but are only compiled when `athena-orm/migrations` is required.
They are executed via commands of the [console](/Console/) component, so add it to your `shard.yml` as well:

```yaml
dependencies:
  athena-console:
    github: athena-framework/console
    version: ~> 0.5.0
```

Then, in the entry point of the console application, require both bundles, `athena-orm/migrations` and the migrations themselves, and configure the namespace and directory of the migrations:

```crystal
require "athena-console/bundle"
require "athena-orm/bundle"
require "athena-orm/migrations"
require "pg"

require "./migrations/*"

ADI.configure({
  orm: {
    url:        ENV["DATABASE_URL"],
    migrations: {
      namespace: "App::Migrations",
      directory: "#{__DIR__}/migrations",
    },
  },
})

ACON::Application.new("My App", "1.0.0", ADI.container).run
```

Within an [Athena Framework](/Framework/) application, also require `athena`, and run the application via [ATH.run_console](/Framework/#Athena::Framework.run_console) instead.

Only the migrations in the configured namespace are executed, and new ones are generated in it, within the configured directory.
Create the directory before building the application, as requiring a directory that doesn't exist is a compile-time error.
See [AORM::Bundle](/ORM/Bundle/) for the other configuration properties, such as the name of the table executed migrations are recorded in.

## Generating Migrations

The `orm:migrations:generate` command generates a blank migration in the configured directory:

```text
$ ./bin/console orm:migrations:generate
 Generated new migration class to "/app/src/migrations/version20261014120000.cr"

 Rebuild the application for the migration to be available.

 To run just this migration for testing purposes, you can use orm:migrations:execute --up 'App::Migrations::Version20261014120000'

 To revert the migration you can use orm:migrations:execute --down 'App::Migrations::Version20261014120000'
```

Its name contains the current UTC time, so that migrations are executed in the order they were generated:

```crystal
class App::Migrations::Version20261014120000 < AORM::Migrations::AbstractMigration
  def description : String
    ""
  end

  def up : Nil
    # this up migration is auto-generated, please modify it to your needs
  end

  def down : Nil
    # this down migration is auto-generated, please modify it to your needs
  end
end
```

NOTE: Migrations are compiled into the application, so it must be rebuilt after a migration is generated or changed for the commands to see it.

TIP: The `shards run` command makes it easy to run one-off console commands. E.g. `shards run console -- orm:migrations:generate`

## Writing Migrations

A migration adds the SQL that applies its change in `#up`, and the SQL that reverts it in `#down`, via `#add_sql`.
The `#description` is shown when listing the migrations:

```crystal
class App::Migrations::Version20261014120000 < AORM::Migrations::AbstractMigration
  def description : String
    "Create the posts table"
  end

  def up : Nil
    self.add_sql "CREATE TABLE posts (id BIGSERIAL NOT NULL, title VARCHAR(255) NOT NULL, created_at TIMESTAMP(0) NOT NULL, PRIMARY KEY (id))"
  end

  def down : Nil
    self.add_sql "DROP TABLE posts"
  end
end
```

The version of a migration is the fully qualified name of its type, e.g. `App::Migrations::Version20261014120000`, and migrations are executed in the order of their versions.

Values are bound to the SQL as parameters, optionally converted through the [AORM::Types::Type](/ORM/Types/Type/) named at the same position:

```crystal
def up : Nil
  self.add_sql "INSERT INTO posts (title, created_at) VALUES (?, ?)", ["Hello World", Time.utc], [nil, AORM::Types::DATETIME] of String?
end
```

The SQL is only executed once `#up` or `#down` returns.
The `#connection` of a migration can be used to read the data it needs, but what's executed through it directly isn't part of the migration's SQL.
`#pre_up` and `#pre_down` run before `#up` and `#down` add the SQL, and `#post_up` and `#post_down` after it's executed.

A new instance of a migration is created each time it's executed, via `.new` with just the connection, so a migration can't define its own `#initialize`.

### Conditions

A migration may depend on the state of the database, or on the database it's executed on:

* `#skip_if` stops the migration without executing its SQL, and without recording it as executed
* `#abort_if` fails the migration, which stops the remaining migrations from being executed
* `#warn_if` logs a warning, and continues

```crystal
def up : Nil
  self.abort_if !self.platform.is_a?(AORM::Platforms::Postgres), "This migration only supports PostgreSQL."

  self.add_sql "CREATE EXTENSION IF NOT EXISTS pg_trgm"
end
```

A migration whose change can't be reverted calls `#raise_irreversible_migration_exception` in its `#down`.
A `#down` that isn't defined fails the migration as well.

### Transactions

Each migration is executed in a transaction, which is rolled back if the migration fails or is skipped.
A migration returning `false` from `#transactional?` is executed without one.
Setting the `orm.migrations.transactional` configuration property to `false` generates migrations that do so.

WARNING: Some databases, such as MySQL and MariaDB, implicitly commit the transaction when a statement changes the schema, such as `CREATE TABLE`.
Statements executed before such a statement can't be rolled back if a later one fails, so it's best to disable transactions in migrations that change the schema on those databases.

## Executing Migrations

The `orm:migrations:migrate` command migrates the database to the latest version, executing the `#up` of each migration that hasn't been executed yet:

```text
$ ./bin/console orm:migrations:migrate
 WARNING! You are about to execute a migration that could result in schema changes and data loss. Are you sure you wish to continue? (yes/no) [yes]:
 > yes

[notice] Migrating up to App::Migrations::Version20261015090000
[notice] finished in 6ms, 2 migrations executed, 2 sql queries

 [OK] Successfully migrated to version: App::Migrations::Version20261015090000
```

Given an older version, it migrates down instead, executing the `#down` of each executed migration after that version.
Besides a migration's fully qualified name, a version may be one of these aliases, see [AORM::Migrations::Version::AliasResolver](/ORM/Migrations/Version/AliasResolver/) for all of them:

* `first` - before the first migration, so every executed migration is reverted
* `prev` - the migration executed before the last one, so the last one is reverted
* `next` - the first migration that hasn't been executed
* `latest` - the last migration, which is the default

```text
$ ./bin/console orm:migrations:migrate prev
```

The `orm:migrations:execute` command executes specific migrations up, or down with `--down`, whether they've already been executed or not:

```text
$ ./bin/console orm:migrations:execute 'App::Migrations::Version20261014120000' --down
```

Both commands support these options:

* `--dry-run` - Logs the SQL that would be executed without executing it
* `--query-time` - Logs how long each query took
* `--no-interaction` (`-n`) - Doesn't ask for confirmation, such as when deploying

Their progress is logged to the output: notices by default, the migrations being executed with `-v`, and each executed query with `-vv`.

## Checking the Status

The `orm:migrations:status` command shows the configuration, the current, previous, next and latest versions, and how many migrations are available, executed, and new.
The `orm:migrations:list` command lists every migration and whether it's been executed:

```text
$ ./bin/console orm:migrations:list
+-------------------------------------------------------------------------------------------------------------------+
| Migration Versions                                                                                                |
+----------------------------------------+----------+---------------------+----------------+------------------------+
| Migration                              | Status   | Migrated At         | Execution Time | Description            |
+----------------------------------------+----------+---------------------+----------------+------------------------+
| App::Migrations::Version20261014120000 | migrated | 2026-10-15 09:12:31 | 0.005s         | Create the posts table |
| App::Migrations::Version20261015090000 | migrated | 2026-10-15 09:12:31 | 0s             | Add the first post     |
+----------------------------------------+----------+---------------------+----------------+------------------------+
```

Executed migrations that are no longer available, such as after renaming one, are listed as `migrated, not available`, and `orm:migrations:migrate` asks for confirmation before executing anything else.

## Managing the Version Table

Executed migrations are recorded in the `athena_orm_migration_versions` table, which `orm:migrations:migrate` and `orm:migrations:execute` create if it doesn't exist yet.
The `orm:migrations:sync-metadata-storage` command creates it without executing any migration.

The `orm:migrations:version` command records migrations as executed with `--add`, or not with `--delete`, without executing them:

```text
$ ./bin/console orm:migrations:version 'App::Migrations::Version20261014120000' --add
$ ./bin/console orm:migrations:version --delete --all
```

TIP: To start using migrations with an existing database, write a first migration creating its current schema.
Then create the table in that database with `orm:migrations:sync-metadata-storage`, and record the migration as executed with `orm:migrations:version --add`.
New databases get the same schema by executing it.

## Testing

[AORM::Spec.migrate_database](/ORM/Spec/#Athena::ORM::Spec.migrate_database(container)) migrates the test database to the latest version before the specs run, see [testing](/ORM/#testing).
