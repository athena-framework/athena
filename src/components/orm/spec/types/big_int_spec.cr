require "../spec_helper"

struct BigIntTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::BigInt

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::BigInt.new
  end

  def test_converts_to_crystal_value : Nil
    @type.to_crystal_value(1_i64, @platform).should eq 1_i64
    @type.to_crystal_value("2", @platform).should eq 2_i64
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  def test_rejects_other_values : Nil
    expect_raises(AORM::Exception::ValueNotConvertible, %(Could not convert database value "true" to type "bigint".)) do
      @type.to_crystal_value(true, @platform)
    end
  end

  def test_rejects_unparsable_values : Nil
    ex = expect_raises(AORM::Exception::ValueNotConvertible, %(Could not convert database value "abc" to type "bigint".)) do
      @type.to_crystal_value("abc", @platform)
    end

    ex.cause.should be_a ArgumentError
  end
end
