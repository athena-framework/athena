require "./spec_helper"

struct PersisterHelperTest < ASPEC::TestCase
  def test_type_of_column_raises_for_an_unmapped_column : Nil
    em = MockEntityManager.new MockConnection.new

    expect_raises AORM::Exception::Runtime, %(Could not resolve type of column "nope" of class "ForumUser") do
      AORM::PersisterHelper.type_of_column "nope", em.class_metadata(ForumUser), em
    end
  end
end
