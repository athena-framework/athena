require "../spec_helper"

struct AbstractMySQLPlatformTest < ASPEC::TestCase
  def test_mysql_does_not_support_returning : Nil
    AORM::Platforms::MySQL.new.supports_returning?.should be_false
  end

  # Without `ANSI_QUOTES`, MySQL and MariaDB read a double-quoted name as a string literal.
  def test_quote_single_identifier_uses_backticks : Nil
    AORM::Platforms::MySQL.new.quote_single_identifier("groups").should eq "`groups`"
    AORM::Platforms::Maria.new.quote_single_identifier("groups").should eq "`groups`"
  end

  def test_quote_single_identifier_escapes_backticks : Nil
    AORM::Platforms::MySQL.new.quote_single_identifier("we`ird").should eq "`we``ird`"
  end
end

struct MySQLPlatformDeclarationTest < ASPEC::TestCase
  @platform : AORM::Platforms::MySQL = AORM::Platforms::MySQL.new

  def test_string_declarations : Nil
    @platform.string_type_declaration_sql(column length: 16).should eq "VARCHAR(16)"
    @platform.string_type_declaration_sql(column fixed: true).should eq "CHAR"
    @platform.string_type_declaration_sql(column length: 16, fixed: true).should eq "CHAR(16)"
  end

  def test_varchar_declaration_requires_a_length : Nil
    expect_raises(Exception, "Length required") { @platform.string_type_declaration_sql column }
  end

  def test_guid_declaration_is_a_fixed_length_string : Nil
    @platform.guid_type_declaration_sql(column).should eq "CHAR(36)"
  end

  def test_date_time_declaration : Nil
    @platform.date_time_type_declaration_sql(column).should eq "DATETIME"
  end

  def test_integer_declarations : Nil
    @platform.integer_type_declaration_sql(column).should eq "INTEGER"
    @platform.integer_type_declaration_sql(column auto_increment: true).should eq "INTEGER AUTO_INCREMENT"
    @platform.big_int_type_declaration_sql(column).should eq "BIGINT"
    @platform.big_int_type_declaration_sql(column unsigned: true, auto_increment: true).should eq "BIGINT UNSIGNED AUTO_INCREMENT"
  end

  def test_numeric_declarations : Nil
    @platform.small_int_type_declaration_sql(column).should eq "SMALLINT"
    @platform.float_declaration_sql(column).should eq "DOUBLE PRECISION"
    @platform.small_float_declaration_sql(column).should eq "FLOAT"
    @platform.decimal_type_declaration_sql(column precision: 10, scale: 2).should eq "NUMERIC(10, 2)"
  end

  def test_numeric_declarations_can_be_unsigned : Nil
    @platform.small_int_type_declaration_sql(column unsigned: true).should eq "SMALLINT UNSIGNED"
    @platform.float_declaration_sql(column unsigned: true).should eq "DOUBLE PRECISION UNSIGNED"
    @platform.decimal_type_declaration_sql(column precision: 10, scale: 2, unsigned: true).should eq "NUMERIC(10, 2) UNSIGNED"
  end

  @[DataProvider("blob_lengths")]
  def test_blob_declaration_fits_the_length(length : Int32?, declaration : String) : Nil
    @platform.blob_type_declaration_sql(column length: length).should eq declaration
  end

  def blob_lengths : Hash
    {
      "no length" => {nil, "LONGBLOB"},
      "tiny"      => {255, "TINYBLOB"},
      "regular"   => {65_535, "BLOB"},
      "medium"    => {16_777_215, "MEDIUMBLOB"},
      "long"      => {16_777_216, "LONGBLOB"},
    }
  end

  def test_binary_declaration : Nil
    @platform.binary_type_declaration_sql(column length: 16).should eq "VARBINARY(16)"
    @platform.binary_type_declaration_sql(column length: 16, fixed: true).should eq "BINARY(16)"
  end

  def test_varbinary_declaration_requires_a_length : Nil
    expect_raises(Exception, "Length required") { @platform.binary_type_declaration_sql column }
  end

  private def column(*, length : Int32? = nil, precision : Int32? = nil, scale : Int32? = nil, unsigned : Bool = false, fixed : Bool = false, auto_increment : Bool = false) : AORM::Schema::Column
    AORM::Schema::Column.new("c", AORM::Types::Type.get_type("string")).tap do |c|
      c.auto_increment = auto_increment
      c.length = length
      c.precision = precision
      c.scale = scale
      c.unsigned = unsigned
      c.fixed = fixed
    end
  end
end
