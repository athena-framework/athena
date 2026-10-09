require "../spec_helper"

struct BinaryTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Binary

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Binary.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value(Bytes[1, 2], @platform).should eq Bytes[1, 2]
    @type.to_crystal_value("ab", @platform).should eq "ab".to_slice
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_rejects_other_values : Nil
    expect_raises(Exception, "Binary cannot accept Int32") do
      @type.to_crystal_value(1, @platform)
    end
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => Bytes[1, 2].as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq Bytes[1, 2]
  end
end
