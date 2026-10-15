require "../schema/metadata/metadata_provider_interface"

# The metadata provider of `AORM::Platforms::MySQL` and `AORM::Platforms::Maria`, reading the database the connection uses.
class Athena::ORM::Platforms::MySQLMetadataProvider
  include Athena::ORM::Schema::Metadata::MetadataProviderInterface

  @database_name : String

  # Raises if the connection doesn't use a database.
  def initialize(@connection : AORM::Connection)
    database_name = @connection.fetch_one "SELECT DATABASE()"

    raise "A database is required for the method: #{self.class}#initialize." if database_name.nil?

    @database_name = database_name.as(String)
  end

  # :inherit:
  def all_table_names : Array(AORM::Schema::Metadata::TableMetadataRow)
    sql = <<-SQL
      SELECT TABLE_NAME
      FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = ?
        AND TABLE_TYPE = 'BASE TABLE'
      ORDER BY TABLE_NAME
      SQL

    rows = [] of AORM::Schema::Metadata::TableMetadataRow

    @connection.execute_query sql, [@database_name] of DB::Any, [] of String? do |rs|
      rs.each do
        rows << AORM::Schema::Metadata::TableMetadataRow.new nil, rs.read(String)
      end
    end

    rows
  end
end
