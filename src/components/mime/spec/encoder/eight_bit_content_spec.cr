require "../spec_helper"

struct EightBitContentEncoderTest < ASPEC::TestCase
  def test_name : Nil
    AMIME::Encoder::EightBitContent.new.name.should eq "8bit"
  end

  def test_encodes_string : Nil
    AMIME::Encoder::EightBitContent.new.encode("123").should eq "123"
    AMIME::Encoder::EightBitContent.new.encode("123456").should eq "123456"
    AMIME::Encoder::EightBitContent.new.encode("123456789").should eq "123456789"
  end

  def test_encodes_io : Nil
    AMIME::Encoder::EightBitContent.new.encode(IO::Memory.new "123").should eq "123"
    AMIME::Encoder::EightBitContent.new.encode(IO::Memory.new "123456").should eq "123456"
    AMIME::Encoder::EightBitContent.new.encode(IO::Memory.new "123456789").should eq "123456789"
  end
end
