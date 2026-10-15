require "../spec_helper"

struct HydrationTest < ASPEC::TestCase
  def test_parent_object_of_relation_not_found : Nil
    AORM::Exception::Hydration.parent_object_of_relation_not_found("a", "u").message.should eq "The parent object of entity result with alias 'a' was not found. The parent alias is 'u'."
  end
end
