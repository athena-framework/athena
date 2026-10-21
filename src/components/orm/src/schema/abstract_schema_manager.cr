# Inspects a database's schema according to the dialect of its platform.
#
# Each platform provides its own, see `AORM::Connection#create_schema_manager`:
#
# ```
# em.connection.create_schema_manager.table_exists? "users" # => true
# ```
#
# TODO: Only listing tables is supported so far.
abstract class Athena::ORM::Schema::AbstractSchemaManager
  protected getter current_schema_name : String? { self.determine_current_schema_name }

  def initialize(
    @connection : AORM::Connection,
    @platform : AORM::Platforms::Platform,
  ); end

  # Returns `true` if all the tables named *names* exist.
  # Names are compared case-insensitively, and a table outside the current schema is named `schema.table`.
  def tables_exist?(names : Enumerable(String)) : Bool
    introspected_names = self.introspect_table_names.map &.downcase

    names.all? { |name| introspected_names.includes? name.downcase }
  end

  # :ditto:
  def tables_exist?(*names : String) : Bool
    self.tables_exist? names
  end

  # Returns `true` if the table named *name* exists.
  def table_exists?(name : String) : Bool
    self.tables_exist? name
  end

  # Returns the names of the database's tables.
  # A table outside the current schema is named `schema.table`.
  def introspect_table_names : Array(String)
    current_schema_name = self.current_schema_name

    @platform.create_metadata_provider(@connection).all_table_names.map do |row|
      schema_name = row.schema_name

      schema_name.nil? || schema_name == current_schema_name ? row.table_name : "#{schema_name}.#{row.table_name}"
    end
  end

  # Returns the name of the schema the connection uses by default, as read from the database.
  protected def determine_current_schema_name : String?
    nil
  end
end
