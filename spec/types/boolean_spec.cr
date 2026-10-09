require "../spec_helper"

struct BooleanTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Boolean

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Boolean.new
  end

  def test_converts_to_db_value : Nil
    @platform.db_boolean = true
    @type.to_db(true, @platform).should eq true

    @platform.db_boolean = false
    @type.to_db(false, @platform).should eq false
  end

  def test_converts_to_crystal_value : Nil
    @platform.crystal_boolean = true
    @type.to_crystal_value(true, @platform).should eq true

    @platform.crystal_boolean = false
    @type.to_crystal_value(false, @platform).should eq false
  end

  def test_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end
end
