require "../schema/metadata/metadata_provider_interface"

# The metadata provider of `AORM::Platforms::SQLite`.
class Athena::ORM::Platforms::SQLiteMetadataProvider
  include Athena::ORM::Schema::Metadata::MetadataProviderInterface

  def initialize(@connection : AORM::Connection); end

  # :inherit:
  #
  # Excludes SQLite's internal tables, and the tables SpatiaLite creates.
  def all_table_names : Array(AORM::Schema::Metadata::TableMetadataRow)
    sql = <<-SQL
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND #{self.build_table_name_predicate "name"}
      SQL

    rows = [] of AORM::Schema::Metadata::TableMetadataRow

    @connection.execute_query sql do |rs|
      rs.each do
        rows << AORM::Schema::Metadata::TableMetadataRow.new nil, rs.read(String)
      end
    end

    rows
  end

  private def build_table_name_predicate(column_name : String) : String
    "#{column_name} NOT IN ('geometry_columns', 'spatial_ref_sys', 'sqlite_sequence')"
  end
end
