require "../spec_helper"

struct SQLitePlatformDeclarationTest < ASPEC::TestCase
  @platform : AORM::Platforms::SQLite = AORM::Platforms::SQLite.new

  # A length is optional for `VARCHAR` columns on SQLite.
  def test_string_declarations : Nil
    @platform.string_type_declaration_sql(column).should eq "VARCHAR"
    @platform.string_type_declaration_sql(column length: 16).should eq "VARCHAR(16)"
    @platform.string_type_declaration_sql(column length: 16, fixed: true).should eq "CHAR(16)"
  end

  def test_guid_declaration_is_a_fixed_length_string : Nil
    @platform.guid_type_declaration_sql(column).should eq "CHAR(36)"
  end

  def test_date_time_declaration : Nil
    @platform.date_time_type_declaration_sql(column).should eq "DATETIME"
  end

  def test_numeric_declarations : Nil
    @platform.small_int_type_declaration_sql(column).should eq "SMALLINT"
    @platform.float_declaration_sql(column).should eq "DOUBLE PRECISION"
    @platform.small_float_declaration_sql(column).should eq "REAL"
  end

  def test_integer_declarations : Nil
    @platform.integer_type_declaration_sql(column).should eq "INTEGER"
    @platform.integer_type_declaration_sql(column auto_increment: true).should eq "INTEGER PRIMARY KEY AUTOINCREMENT"
    @platform.big_int_type_declaration_sql(column).should eq "BIGINT"
  end

  # SQLite only auto-increments `INTEGER PRIMARY KEY` columns.
  def test_auto_increment_small_and_big_ints_are_declared_as_integer : Nil
    @platform.small_int_type_declaration_sql(column auto_increment: true).should eq "INTEGER PRIMARY KEY AUTOINCREMENT"
    @platform.big_int_type_declaration_sql(column auto_increment: true).should eq "INTEGER PRIMARY KEY AUTOINCREMENT"
  end

  def test_binary_declarations_are_blob : Nil
    @platform.blob_type_declaration_sql(column).should eq "BLOB"
    @platform.binary_type_declaration_sql(column length: 16).should eq "BLOB"
  end

  private def column(*, length : Int32? = nil, fixed : Bool = false, auto_increment : Bool = false) : AORM::Schema::Column
    AORM::Schema::Column.new("c", AORM::Types::Type.get_type("string")).tap do |c|
      c.length = length
      c.fixed = fixed
      c.auto_increment = auto_increment
    end
  end
end
