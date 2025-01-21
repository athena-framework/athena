require "../../spec_helper"

struct AlternativePartTest < ASPEC::TestCase
  def test_constructor : Nil
    part = AMIME::Part::Multipart::Alternative.new
    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "alternative"
  end
end
