# Configures how `AORM::Migrations::Migrator` executes a plan.
class Athena::ORM::Migrations::MigratorConfiguration
  # Whether to log the SQL the migrations would execute instead of executing it, and leave the metadata storage unchanged.
  property? dry_run : Bool

  # Whether to log every query the migrations execute, with how long it took.
  property? time_all_queries : Bool

  # Whether an empty plan isn't an error, such as when the database is already at the requested version.
  property? no_migration_exception : Bool

  def initialize(
    @dry_run : Bool = false,
    @time_all_queries : Bool = false,
    @no_migration_exception : Bool = false,
  ); end
end
