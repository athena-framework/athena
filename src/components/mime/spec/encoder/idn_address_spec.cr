require "../spec_helper"

struct IDNAddressEncoderTest < ASPEC::TestCase
  def test_encodes_string : Nil
    AMIME::Encoder::IDNAddress.new.encode("test@fußball.test").should eq "test@xn--fuball-cta.test"
  end
end
