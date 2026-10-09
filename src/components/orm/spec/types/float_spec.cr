require "../spec_helper"

struct FloatTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Float

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Float.new
  end

  # Drivers return single-precision columns (e.g. Postgres `REAL`) as `Float32`, and SQLite numeric columns as `Int64`.
  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value(1.5, @platform).should eq 1.5
    @type.to_crystal_value(1.5_f32, @platform).should eq 1.5
    @type.to_crystal_value(2_i64, @platform).should eq 2.0
    @type.to_crystal_value("1.5", @platform).should eq 1.5
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_rejects_non_numeric_values : Nil
    expect_raises(Exception, "Float cannot accept Bool") do
      @type.to_crystal_value(true, @platform)
    end
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => 1.5.as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq 1.5
  end
end
