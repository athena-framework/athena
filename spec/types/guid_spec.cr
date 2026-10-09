require "../spec_helper"

struct GuidTypeTest < ASPEC::TestCase
  @platform : MockPlatform
  @type : AORM::Types::Guid

  def initialize
    @platform = MockPlatform.new
    @type = AORM::Types::Guid.new
  end

  # Postgres returns `UUID` columns as `UUID`; others store them as text.
  def test_converts_to_crystal_value : Nil
    uuid = UUID.new "4f8b3c2a-1d5e-4b7a-9c3f-2e6d8a1b5c7e"

    @type.to_crystal_value(uuid, @platform).should eq uuid
    @type.to_crystal_value(uuid.to_s, @platform).should eq uuid
  end

  def test_null_converts_to_crystal_value_returns_nil : Nil
    @type.to_crystal_value(nil, @platform).should be_nil
  end

  # Drivers can't bind `UUID`, but every database accepts its string form.
  def test_converts_to_db_value_as_a_string : Nil
    @type.to_db(UUID.new("4f8b3c2a-1d5e-4b7a-9c3f-2e6d8a1b5c7e"), @platform).should eq "4f8b3c2a-1d5e-4b7a-9c3f-2e6d8a1b5c7e"
    @type.to_db(nil, @platform).should be_nil
  end

  def test_reads_from_a_result_set : Nil
    rs = FakeResultSet.new [{"c" => "4f8b3c2a-1d5e-4b7a-9c3f-2e6d8a1b5c7e".as(DB::Any)}]
    rs.move_next

    @type.to_crystal_value(rs, @platform).should eq UUID.new("4f8b3c2a-1d5e-4b7a-9c3f-2e6d8a1b5c7e")
  end
end
