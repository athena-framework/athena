require "../spec_helper"
require "big"

struct NumberTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Number

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Number.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value("12.3400", @platform).should eq BigDecimal.new("12.34")
    @type.to_crystal_value(BigDecimal.new("1.5"), @platform).should eq BigDecimal.new("1.5")
    @type.to_crystal_value(12_i64, @platform).should eq BigDecimal.new(12)
  end

  # A float is converted through its shortest representation, so `0.1` stays exactly `0.1`.
  def test_converts_floats_through_their_shortest_representation : Nil
    @type.to_crystal_value(0.1, @platform).should eq BigDecimal.new("0.1")
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  # Drivers can't bind `BigDecimal`, but accept its string form for decimal columns.
  def test_converts_to_db_value_as_a_string : Nil
    @type.to_db(BigDecimal.new("12.34"), @platform).should eq "12.34"
    @type.to_db(nil, @platform).should be_nil
  end

  # This file requires `big` after the ORM, so the type is registered regardless of require order.
  def test_is_registered_when_big_decimal_is_available : Nil
    AORM::Types::Type.get_type(AORM::Types::NUMBER).should be_a AORM::Types::Number
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => "12.34".as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq BigDecimal.new("12.34")
  end
end
