require "../spec_helper"

struct ReturningGeneratorTest < ASPEC::TestCase
  def test_consume_row_reads_typed_value_for_single_pk : Nil
    em = MockEntityManager.new(MockConnection.new)
    metadata = em.class_metadata(ForumUser)
    generator = AORM::ID::ReturningGenerator.new

    rs = FakeResultSet.new([{"id" => 99.as(DB::Any)}])
    rs.move_next

    id_hash = generator.consume_row rs, metadata, AORM::Platforms::SQLite.new

    id_hash.size.should eq 1
    id_hash["id"].value.should eq 99
  end

  def test_consume_row_reads_typed_values_for_composite_pk : Nil
    em = MockEntityManager.new(MockConnection.new)
    metadata = em.class_metadata(CompositeAutoItem)
    generator = AORM::ID::ReturningGenerator.new

    rs = FakeResultSet.new([{"tenant_id" => 7_i64.as(DB::Any), "item_id" => 12_i64.as(DB::Any)}])
    rs.move_next

    id_hash = generator.consume_row rs, metadata, AORM::Platforms::SQLite.new

    id_hash.size.should eq 2
    id_hash["tenant_id"].value.should eq 7
    id_hash["item_id"].value.should eq 12
  end
end
