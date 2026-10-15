# A table as read from a database's catalog, see `AORM::Schema::Metadata::MetadataProviderInterface#all_table_names`.
record Athena::ORM::Schema::Metadata::TableMetadataRow,
  # Returns the name of the schema the table is in, or `nil` on platforms without schemas.
  schema_name : String?,
  # Returns the name of the table.
  table_name : String
