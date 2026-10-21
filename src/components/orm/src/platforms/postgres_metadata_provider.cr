require "../schema/metadata/metadata_provider_interface"

# The metadata provider of `AORM::Platforms::Postgres`.
class Athena::ORM::Platforms::PostgresMetadataProvider
  include Athena::ORM::Schema::Metadata::MetadataProviderInterface

  def initialize(@connection : AORM::Connection); end

  # :inherit:
  #
  # Excludes the system schemas, and the tables PostGIS creates.
  def all_table_names : Array(AORM::Schema::Metadata::TableMetadataRow)
    sql = <<-SQL
      SELECT n.nspname,
             c.relname
      FROM pg_class c
               INNER JOIN pg_namespace n
                          ON n.oid = c.relnamespace
      WHERE #{self.build_namespace_name_predicate "n.nspname"}
        AND #{self.build_table_predicate "c.relkind", "c.relname"}
      ORDER BY n.nspname,
               c.relname
      SQL

    rows = [] of AORM::Schema::Metadata::TableMetadataRow

    @connection.execute_query sql do |rs|
      rs.each do
        rows << AORM::Schema::Metadata::TableMetadataRow.new rs.read(String), rs.read(String)
      end
    end

    rows
  end

  private def build_namespace_name_predicate(column_name : String) : String
    "#{column_name} NOT LIKE 'pg\\_%' AND #{column_name} != 'information_schema'"
  end

  # See https://www.postgresql.org/docs/current/catalog-pg-class.html.
  private def build_table_predicate(kind_column_name : String, name_column_name : String) : String
    # r = ordinary table, p = partitioned table
    "#{kind_column_name} IN ('r', 'p') AND #{name_column_name} NOT IN ('geometry_columns', 'spatial_ref_sys')"
  end
end
