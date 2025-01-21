require "../../spec_helper"

struct DigestPartTest < ASPEC::TestCase
  def test_constructor : Nil
    part = AMIME::Part::Multipart::Digest.new
    part.media_type.should eq "multipart"
    part.media_sub_type.should eq "digest"
  end
end
