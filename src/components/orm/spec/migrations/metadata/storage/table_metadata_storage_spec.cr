require "../../spec_helper"

private def rows(*rows : Hash(String, _)) : Array(Hash(String, DB::Any))
  rows.map(&.transform_values(&.as(DB::Any))).to_a
end

private NO_ROWS = [] of Hash(String, DB::Any)

private def version(version : String) : AORM::Migrations::Version
  AORM::Migrations::Version.new version
end

struct TableMetadataStorageTest < ASPEC::TestCase
  @wrapped : MockConnection
  @storage : AORM::Migrations::Metadata::Storage::TableMetadataStorage

  def initialize
    @wrapped = MockConnection.new
    @storage = AORM::Migrations::Metadata::Storage::TableMetadataStorage.new AORM::Connection.new(@wrapped)
  end

  def test_executed_migrations_is_empty_without_the_table : Nil
    @wrapped.queue_result NO_ROWS

    @storage.executed_migrations.size.should eq 0
    @wrapped.executed_statements.size.should eq 1
  end

  def test_ensure_initialized_creates_the_table : Nil
    @wrapped.queue_result NO_ROWS

    @storage.ensure_initialized

    @wrapped.executed_statements.last[0].should eq "CREATE TABLE athena_orm_migration_versions (" \
                                                   "version VARCHAR(191) NOT NULL, executed_at DATETIME DEFAULT NULL, execution_time INTEGER DEFAULT NULL, " \
                                                   "PRIMARY KEY (version))"
  end

  def test_ensure_initialized_does_not_create_an_existing_table : Nil
    @wrapped.queue_result rows({"name" => "athena_orm_migration_versions"})

    @storage.ensure_initialized

    @wrapped.executed_statements.none?(&.[0].starts_with?("CREATE TABLE")).should be_true
  end

  def test_tables_are_not_listed_again_once_initialized : Nil
    @wrapped.queue_result NO_ROWS
    @storage.ensure_initialized
    statement_count = @wrapped.executed_statements.size

    @storage.reset

    @wrapped.executed_statements.size.should eq statement_count + 1
    @wrapped.executed_statements.last[0].should eq "DELETE FROM athena_orm_migration_versions WHERE 1 = 1"
  end

  def test_create_table_uses_the_platforms_declarations : Nil
    wrapped = MockConnection.new driver_name: "postgres"
    wrapped.queue_result rows({"current_schema" => "public"})
    wrapped.queue_result NO_ROWS

    AORM::Migrations::Metadata::Storage::TableMetadataStorage.new(AORM::Connection.new wrapped).ensure_initialized

    wrapped.executed_statements.last[0].should eq "CREATE TABLE athena_orm_migration_versions (" \
                                                  "version VARCHAR(191) NOT NULL, executed_at TIMESTAMP(0) WITHOUT TIME ZONE DEFAULT NULL, execution_time INT DEFAULT NULL, " \
                                                  "PRIMARY KEY (version))"
  end

  def test_executed_migrations_are_ordered_by_version : Nil
    executed_at = Time.utc 2026, 10, 14, 12, 30
    @wrapped.queue_result rows({"name" => "athena_orm_migration_versions"})
    @wrapped.queue_result rows(
      {"version" => "App::Version2", "executed_at" => executed_at, "execution_time" => 1500},
      {"version" => "App::Version1", "executed_at" => nil, "execution_time" => nil},
    )

    migrations = @storage.executed_migrations

    @wrapped.executed_statements.last[0].should eq "SELECT version, executed_at, execution_time FROM athena_orm_migration_versions"
    migrations.items.map(&.version.to_s).should eq ["App::Version1", "App::Version2"]
    migrations.first.executed_at.should be_nil
    migrations.first.execution_time.should be_nil
    migrations.last.executed_at.should eq executed_at
    migrations.last.execution_time.should eq 1500.milliseconds
  end

  def test_complete_records_an_applied_migration : Nil
    @wrapped.queue_result rows({"name" => "athena_orm_migration_versions"})
    executed_at = Time.utc 2026, 10, 14, 12, 30
    result = AORM::Migrations::Version::ExecutionResult.new version("App::Version1"), :up, executed_at
    result.time = 1234.6.milliseconds

    @storage.complete result

    @wrapped.executed_statements.last.should eq({
      "INSERT INTO athena_orm_migration_versions (version, executed_at, execution_time) VALUES (?, ?, ?)",
      ["App::Version1", executed_at, 1235] of DB::Any,
    })
  end

  def test_complete_forgets_a_reverted_migration : Nil
    @wrapped.queue_result rows({"name" => "athena_orm_migration_versions"})

    @storage.complete AORM::Migrations::Version::ExecutionResult.new(version("App::Version1"), :down)

    @wrapped.executed_statements.last.should eq({
      "DELETE FROM athena_orm_migration_versions WHERE version = ?",
      ["App::Version1"] of DB::Any,
    })
  end

  def test_using_the_storage_before_it_is_initialized_raises : Nil
    @wrapped.queue_result NO_ROWS

    expect_raises AORM::Migrations::Exception::MetadataStorageError, "The metadata storage is not initialized, please run the sync-metadata-storage command to fix this issue." do
      @storage.reset
    end
  end

  def test_sql_for_an_applied_migration : Nil
    result = AORM::Migrations::Version::ExecutionResult.new version("App::Version1"), :up, Time.utc(2026, 10, 14, 12, 30)

    @storage.sql(result).map(&.to_s).should eq [
      "-- Version App::Version1 update table metadata",
      "INSERT INTO athena_orm_migration_versions (version, executed_at, execution_time) VALUES ('App::Version1', '2026-10-14 12:30:00', 0)",
    ]
  end

  def test_sql_for_a_reverted_migration : Nil
    result = AORM::Migrations::Version::ExecutionResult.new version("App::Version1"), :down

    @storage.sql(result).map(&.to_s).should eq [
      "-- Version App::Version1 update table metadata",
      "DELETE FROM athena_orm_migration_versions WHERE version = 'App::Version1'",
    ]
  end

  def test_configured_table_and_column_names_are_used : Nil
    configuration = AORM::Migrations::Metadata::Storage::TableMetadataStorageConfiguration.new(
      table_name: "migrations",
      version_column_name: "name",
      version_column_length: 255,
      executed_at_column_name: "ran_at",
      execution_time_column_name: "took",
    )
    storage = AORM::Migrations::Metadata::Storage::TableMetadataStorage.new AORM::Connection.new(@wrapped), configuration
    @wrapped.queue_result NO_ROWS
    @wrapped.queue_result NO_ROWS

    storage.ensure_initialized
    storage.executed_migrations

    @wrapped.executed_statements[1][0].should eq "CREATE TABLE migrations (name VARCHAR(255) NOT NULL, ran_at DATETIME DEFAULT NULL, took INTEGER DEFAULT NULL, PRIMARY KEY (name))"
    @wrapped.executed_statements[2][0].should eq "SELECT name, ran_at, took FROM migrations"
  end
end
