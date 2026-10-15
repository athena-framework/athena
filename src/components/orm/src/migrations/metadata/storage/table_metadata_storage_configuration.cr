# Configures the table `AORM::Migrations::Metadata::Storage::TableMetadataStorage` records executed migrations in.
struct Athena::ORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration
  # Returns the name of the table, which may be qualified by its schema, e.g. `schema.table`.
  getter table_name : String

  # Returns the name of the column holding the versions of the executed migrations.
  getter version_column_name : String

  # Returns the length of the version column, which limits the length of the fully qualified names of migrations.
  getter version_column_length : Int32

  # Returns the name of the column holding the time each migration was executed at.
  getter executed_at_column_name : String

  # Returns the name of the column holding how long executing each migration took, in milliseconds.
  getter execution_time_column_name : String

  def initialize(
    @table_name : String = "athena_orm_migration_versions",
    @version_column_name : String = "version",
    @version_column_length : Int32 = 191,
    @executed_at_column_name : String = "executed_at",
    @execution_time_column_name : String = "execution_time",
  ); end
end
