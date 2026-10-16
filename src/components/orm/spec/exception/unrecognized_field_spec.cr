require "../spec_helper"

struct UnrecognizedFieldTest < ASPEC::TestCase
  def test_by_fully_qualified_name : Nil
    expect_raises AORM::Exception::UnrecognizedField, "Unrecognized field: ForumUser#color" do
      raise AORM::Exception::UnrecognizedField.by_fully_qualified_name ForumUser.to_s, "color"
    end
  end
end
