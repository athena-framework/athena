require "../../spec_helper"

struct MixedPartTest < ASPEC::TestCase
  def test_constructor : Nil
    part = AMIME::Part::Multipart::Mixed.new
    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "mixed"
  end
end
