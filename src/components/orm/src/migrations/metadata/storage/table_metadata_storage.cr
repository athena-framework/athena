require "./interface"

# Records the executed migrations in a table of the database they're executed on.
#
# The table is created by `#ensure_initialized`.
#
# TODO: Tables in a different layout, such as when the configured column length is changed after the table is created, aren't detected or upgraded.
class Athena::ORM::Migrations::Metadata::Storage::TableMetadataStorage
  include AORM::Migrations::Metadata::Storage::Interface

  @initialized : Bool = false
  @platform : AORM::Platforms::Platform
  @schema_manager : AORM::Schema::AbstractSchemaManager

  def initialize(
    @connection : AORM::Connection,
    @configuration : AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration = AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration.new,
  )
    @platform = @connection.database_platform
    @schema_manager = @connection.create_schema_manager
  end

  # :inherit:
  #
  # Returns an empty list if the table doesn't exist yet.
  def executed_migrations : AORM::Migrations::Metadata::ExecutedMigrationsList
    return AORM::Migrations::Metadata::ExecutedMigrationsList.new [] of AORM::Migrations::Metadata::ExecutedMigration unless self.initialized?

    self.check_initialization

    sql = "SELECT #{@configuration.version_column_name}, #{@configuration.executed_at_column_name}, #{@configuration.execution_time_column_name} FROM #{@configuration.table_name}"
    executed_at_type = AORM::Types::Type.get_type AORM::Types::DATETIME
    execution_time_type = AORM::Types::Type.get_type AORM::Types::INTEGER

    migrations = [] of AORM::Migrations::Metadata::ExecutedMigration

    @connection.execute_query sql do |rs|
      rs.each do
        version = AORM::Migrations::Version::Version.new rs.read(String)
        executed_at = executed_at_type.to_crystal_value(rs, @platform).as(Time?)
        execution_time = execution_time_type.to_crystal_value(rs, @platform).as(Int32?)

        migrations << AORM::Migrations::Metadata::ExecutedMigration.new version, executed_at, execution_time.try(&.milliseconds)
      end
    end

    AORM::Migrations::Metadata::ExecutedMigrationsList.new migrations.sort_by!(&.version.to_s)
  end

  # :inherit:
  def reset : Nil
    self.check_initialization

    @connection.execute_statement "DELETE FROM #{@configuration.table_name} WHERE 1 = 1"
  end

  # :inherit:
  def complete(result : AORM::Migrations::Version::ExecutionResult) : Nil
    self.check_initialization

    if result.direction.down?
      @connection.execute_statement(
        "DELETE FROM #{@configuration.table_name} WHERE #{@configuration.version_column_name} = ?",
        [result.version.to_s] of DB::Any,
        [AORM::Types::STRING] of String?,
      )

      return
    end

    @connection.execute_statement(
      "INSERT INTO #{@configuration.table_name} (#{@configuration.version_column_name}, #{@configuration.executed_at_column_name}, #{@configuration.execution_time_column_name}) VALUES (?, ?, ?)",
      [result.version.to_s, result.executed_at, result.time.try(&.total_milliseconds.round.to_i32)] of DB::Any,
      [AORM::Types::STRING, AORM::Types::DATETIME, AORM::Types::INTEGER] of String?,
    )
  end

  # Returns the SQL `#complete` would execute for *result*, such as to show it during a dry run.
  def sql(result : AORM::Migrations::Version::ExecutionResult) : Array(AORM::Migrations::Query::Query)
    queries = [AORM::Migrations::Query::Query.new "-- Version #{result.version} update table metadata"]

    if result.direction.down?
      queries << AORM::Migrations::Query::Query.new(
        "DELETE FROM #{@configuration.table_name} WHERE #{@configuration.version_column_name} = #{@platform.quote_string_literal result.version.to_s}"
      )

      return queries
    end

    executed_at = (result.executed_at || Time.utc).to_utc.to_s "%F %T"

    queries << AORM::Migrations::Query::Query.new(
      "INSERT INTO #{@configuration.table_name} (#{@configuration.version_column_name}, #{@configuration.executed_at_column_name}, #{@configuration.execution_time_column_name}) " \
      "VALUES (#{@platform.quote_string_literal result.version.to_s}, #{@platform.quote_string_literal executed_at}, 0)"
    )

    queries
  end

  # :inherit:
  #
  # Creates the table if it doesn't exist.
  def ensure_initialized : Nil
    unless self.initialized?
      @connection.execute_statement self.create_table_sql
    end

    @initialized = true
  end

  private def initialized? : Bool
    @initialized ||= @schema_manager.table_exists? @configuration.table_name
  end

  private def check_initialization : Nil
    raise AORM::Migrations::Exception::MetadataStorageError.not_initialized unless self.initialized?
  end

  # TODO: Build the table via the schema manager once it can create tables.
  private def create_table_sql : String
    version_column = AORM::Schema::Column.new @configuration.version_column_name, AORM::Types::Type.get_type(AORM::Types::STRING)
    version_column.length = @configuration.version_column_length
    executed_at_column = AORM::Schema::Column.new @configuration.executed_at_column_name, AORM::Types::Type.get_type(AORM::Types::DATETIME)
    execution_time_column = AORM::Schema::Column.new @configuration.execution_time_column_name, AORM::Types::Type.get_type(AORM::Types::INTEGER)

    "CREATE TABLE #{@configuration.table_name} (" \
    "#{version_column.name} #{version_column.type.sql_declaration version_column, @platform} NOT NULL, " \
    "#{executed_at_column.name} #{executed_at_column.type.sql_declaration executed_at_column, @platform} DEFAULT NULL, " \
    "#{execution_time_column.name} #{execution_time_column.type.sql_declaration execution_time_column, @platform} DEFAULT NULL, " \
    "PRIMARY KEY (#{version_column.name}))"
  end
end
