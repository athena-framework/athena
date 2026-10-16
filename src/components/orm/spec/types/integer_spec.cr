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

  def test_rejects_other_values : Nil
    expect_raises(AORM::Exception::ValueNotConvertible, %(Could not convert database value "true" to type "integer".)) do
      @type.to_crystal_value(true, @platform)
    end
  end

  def test_rejects_unparsable_values : Nil
    ex = expect_raises(AORM::Exception::ValueNotConvertible, %(Could not convert database value "abc" to type "integer".)) do
      @type.to_crystal_value("abc", @platform)
    end

    ex.cause.should be_a ArgumentError
  end
end
