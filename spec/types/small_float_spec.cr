require "../spec_helper"

struct SmallFloatTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::SmallFloat

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::SmallFloat.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value(1.5, @platform).should eq 1.5_f32
    @type.to_crystal_value(1.5_f32, @platform).should eq 1.5_f32
    @type.to_crystal_value("1.5", @platform).should eq 1.5_f32
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => 1.5.as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq 1.5_f32
  end
end
