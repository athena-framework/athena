require "../spec_helper"

struct QuotedPrintableMIMEHeaderTest < ASPEC::TestCase
  def test_name_is_q : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader.new.name.should eq "Q"
  end

  def test_space_and_tab_never_appear : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader
      .new
      .encode("a \t b")
      .should_not match /[ \t]/
  end

  def test_space_is_represented_by_underscore : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader
      .new
      .encode("a b")
      .should eq "a_b"
  end

  def test_equals_and_question_underscore_are_encoded : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader
      .new
      .encode("=?_")
      .should eq "=3D=3F=5F"
  end

  def test_parans_and_quotes_are_encoded : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader
      .new
      .encode("(\")")
      .should eq "=28=22=29"
  end

  def test_only_chars_allowed_in_phrases_are_used : Nil
    encoder = AMIME::Encoder::QuotedPrintableMIMEHeader.new

    allowed_bytes = [] of Int32
    allowed_bytes.concat ('a'..'z').map(&.ord)
    allowed_bytes.concat ('A'..'Z').map(&.ord)
    allowed_bytes.concat ('0'..'9').map(&.ord)
    allowed_bytes.concat ['!'.ord, '*'.ord, '+'.ord, '-'.ord, '/'.ord]

    (0x00_u8..0xFF_u8).each do |byte|
      io = IO::Memory.new
      io.write_byte byte
      input = io.to_s

      encoded = encoder.encode input

      if allowed_bytes.includes? byte
        encoded.should eq input
      elsif ' '.ord == byte
        # Special case
        encoded.should eq "_"
      else
        encoded.should eq "=#{byte.to_s base: 16, upcase: true, precision: 2}"
      end
    end
  end

  def test_equals_never_appears_at_end_of_line : Nil
    AMIME::Encoder::QuotedPrintableMIMEHeader
      .new
      .encode("a" * 140)
      .should eq <<-TXT
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        TXT
  end
end
