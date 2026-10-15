require "../spec_helper"

private def rows(*rows : Hash(String, _)) : Array(Hash(String, DB::Any))
  rows.map(&.transform_values(&.as(DB::Any))).to_a
end

struct SchemaManagerTest < ASPEC::TestCase
  def test_sqlite_lists_tables_without_qualifying_them : Nil
    wrapped = MockConnection.new
    wrapped.queue_result rows({"name" => "users"}, {"name" => "posts"})

    schema_manager = AORM::Connection.new(wrapped).create_schema_manager
    schema_manager.should be_a AORM::Schema::SQLiteSchemaManager
    schema_manager.introspect_table_names.should eq ["users", "posts"]

    wrapped.executed_statements.last[0].should contain "FROM sqlite_master"
    wrapped.executed_statements.last[0].should contain "NOT IN ('geometry_columns', 'spatial_ref_sys', 'sqlite_sequence')"
  end

  # The schema manager, and the metadata provider it lists tables with, come from the connection's platform.
  def test_comes_from_the_connections_platform : Nil
    wrapped = MockConnection.new
    wrapped.queue_result rows({"name" => "users"})

    AORM::Connection.new(wrapped, MockPlatformDriver.new).create_schema_manager.introspect_table_names.should eq ["users"]
  end

  def test_postgres_qualifies_tables_outside_the_current_schema : Nil
    wrapped = MockConnection.new driver_name: "postgres"
    wrapped.queue_result rows({"current_schema" => "public"})
    wrapped.queue_result rows({"nspname" => "audit", "relname" => "log"}, {"nspname" => "public", "relname" => "users"})

    schema_manager = AORM::Connection.new(wrapped).create_schema_manager
    schema_manager.should be_a AORM::Schema::PostgresSchemaManager
    schema_manager.introspect_table_names.should eq ["audit.log", "users"]

    wrapped.executed_statements.first[0].should eq "SELECT current_schema()"
    wrapped.executed_statements.last[0].should contain "FROM pg_class c"
  end

  def test_postgres_determines_the_current_schema_once : Nil
    wrapped = MockConnection.new driver_name: "postgres"
    wrapped.queue_result rows({"current_schema" => "public"})
    wrapped.queue_result rows({"nspname" => "public", "relname" => "users"})
    wrapped.queue_result rows({"nspname" => "public", "relname" => "users"})

    schema_manager = AORM::Connection.new(wrapped).create_schema_manager
    schema_manager.table_exists?("users").should be_true
    schema_manager.table_exists?("users").should be_true

    wrapped.executed_statements.count(&.[0].==("SELECT current_schema()")).should eq 1
  end

  def test_mysql_lists_the_tables_of_the_current_database : Nil
    wrapped = MockConnection.new driver_name: "mysql"
    wrapped.queue_result rows({"DATABASE()" => "blog"})
    wrapped.queue_result rows({"TABLE_NAME" => "users"})

    schema_manager = AORM::Connection.new(wrapped).create_schema_manager
    schema_manager.should be_a AORM::Schema::MySQLSchemaManager
    schema_manager.introspect_table_names.should eq ["users"]

    wrapped.executed_statements.last[0].should contain "FROM information_schema.TABLES"
    wrapped.executed_statements.last[1].should eq ["blog"] of DB::Any
  end

  def test_mysql_requires_a_database : Nil
    wrapped = MockConnection.new driver_name: "mysql"
    wrapped.queue_result rows({"DATABASE()" => nil})

    expect_raises AORM::Exception::DatabaseRequired, "A database is required for the method: Athena::ORM::Platforms::MySQLMetadataProvider#initialize." do
      AORM::Connection.new(wrapped).create_schema_manager.introspect_table_names
    end
  end

  def test_tables_exist_compares_names_case_insensitively : Nil
    wrapped = MockConnection.new
    3.times { wrapped.queue_result rows({"name" => "Users"}, {"name" => "posts"}) }

    schema_manager = AORM::Connection.new(wrapped).create_schema_manager
    schema_manager.tables_exist?(["users", "POSTS"]).should be_true
    schema_manager.tables_exist?("users", "comments").should be_false
    schema_manager.table_exists?("comments").should be_false
  end
end
