require "../spec_helper"

struct DecimalTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Decimal

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Decimal.new
  end

  # SQLite may return a decimal column as a float or an integer.
  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value("12.3400", @platform).should eq "12.3400"
    @type.to_crystal_value(12.34, @platform).should eq "12.34"
    @type.to_crystal_value(12_i64, @platform).should eq "12"
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => "12.3400".as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq "12.3400"
  end
end
