require "../spec_helper"

struct StringTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::String

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::String.new
  end

  def test_passes_strings_to_db_unchanged : Nil
    @type.to_db("foo", @platform).should eq "foo"
  end

  # A NULL column value must stay NULL rather than becoming an empty string.
  def test_converts_nil_to_db_value : Nil
    @type.to_db(nil, @platform).should be_nil
  end
end
