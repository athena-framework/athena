require "../spec_helper"

struct Base64ContentEncoderTest < ASPEC::TestCase
  def test_name : Nil
    AMIME::Encoder::Base64Content.new.name.should eq "base64"
  end

  def test_encodes_string : Nil
    AMIME::Encoder::Base64Content.new.encode("123").should eq "MTIz\n"               # spellchecker:disable-line
    AMIME::Encoder::Base64Content.new.encode("123456").should eq "MTIzNDU2\n"        # spellchecker:disable-line
    AMIME::Encoder::Base64Content.new.encode("123456789").should eq "MTIzNDU2Nzg5\n" # spellchecker:disable-line
  end

  def test_encodes_io : Nil
    AMIME::Encoder::Base64Content.new.encode(IO::Memory.new "123").should eq "MTIz\n"               # spellchecker:disable-line
    AMIME::Encoder::Base64Content.new.encode(IO::Memory.new "123456").should eq "MTIzNDU2\n"        # spellchecker:disable-line
    AMIME::Encoder::Base64Content.new.encode(IO::Memory.new "123456789").should eq "MTIzNDU2Nzg5\n" # spellchecker:disable-line
  end

  def test_pad_length : Nil
    encoder = AMIME::Encoder::Base64Content.new

    30.times do
      input = String.build do |io|
        io.write_byte rand 255_u8
      end

      # Two bytes of padding for a single byte
      encoder.encode(input).should match /^[a-zA-Z0-9\/+]{2}==$/
    end

    30.times do
      input = String.build do |io|
        io.write_byte rand 255_u8
        io.write_byte rand 255_u8
      end

      # Two bytes has 1 byte of padding
      encoder.encode(input).should match /^[a-zA-Z0-9\/+]{3}=$/
    end

    30.times do
      input = String.build do |io|
        io.write_byte rand 255_u8
        io.write_byte rand 255_u8
        io.write_byte rand 255_u8
      end

      # Three bytes has no padding
      encoder.encode(input).should match /^[a-zA-Z0-9\/+]{4}$/
    end
  end

  def test_max_line_length : Nil
    input = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    AMIME::Encoder::Base64Content
      .new
      .encode(input)
      .lines(chomp: false) # Use lines here to allow ignoring the typos
      .should eq([
        "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXpBQkNERUZHSElKS0xNTk9QUVJT\n",
        "VFVWV1hZWjEyMzQ1Njc4OTBhYmNkZWZnaGlqa2xtbm9wcXJzdHV2d3h5ekFC\n", # spellchecker:disable-line
        "Q0RFRkdISUpLTE1OT1BRUlNUVVZXWFlaMTIzNDU2Nzg5MEFCQ0RFRkdISUpL\n", # spellchecker:disable-line
        "TE1OT1BRUlNUVVZXWFla\n",                                         # spellchecker:disable-line
      ])
  end
end
