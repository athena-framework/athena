require "../spec_helper"

struct SmallIntTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::SmallInt

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::SmallInt.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value(7_i16, @platform).should eq 7_i16
    @type.to_crystal_value(7_i64, @platform).should eq 7_i16
    @type.to_crystal_value("7", @platform).should eq 7_i16
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  # Drivers can't bind `Int16`.
  def test_converts_to_db_value_as_int32 : Nil
    @type.to_db(7_i16, @platform).should eq 7
    @type.to_db(7_i16, @platform).should be_a Int32
    @type.to_db(nil, @platform).should be_nil
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => 7_i64.as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq 7_i16
  end
end
