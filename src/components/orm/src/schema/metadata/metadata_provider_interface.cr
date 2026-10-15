# Reads the metadata of a database's schema objects from its catalog.
#
# Each platform provides its own, see `AORM::Platforms::Platform#create_metadata_provider`.
module Athena::ORM::Schema::Metadata::MetadataProviderInterface
  # Returns the tables of the database, ordered by their schema and name on platforms that support ordering them.
  abstract def all_table_names : Array(AORM::Schema::Metadata::TableMetadataRow)
end
