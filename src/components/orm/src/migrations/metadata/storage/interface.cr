# Records which migrations have been executed.
module Athena::ORM::Migrations::Metadata::Storage::Interface
  # Prepares the storage to record executed migrations, such as by creating the table they're recorded in.
  abstract def ensure_initialized : Nil

  # Returns the migrations that have been executed, ordered by version.
  abstract def executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList

  # Records the migration of *result* as executed if it was applied, or as no longer executed if it was reverted.
  abstract def complete(result : AORM::Migrations::Version::ExecutionResult) : Nil
end
