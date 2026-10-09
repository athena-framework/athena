require "../spec_helper"

struct IntegerTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Integer

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Integer.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value("1", @platform).should eq 1
    @type.to_crystal_value(1, @platform).should eq 1
    @type.to_crystal_value(1.0, @platform).should eq 1
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end
end
