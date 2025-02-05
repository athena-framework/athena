require "../spec_helper"

struct UnstructuredHeaderTest < ASPEC::TestCase
  def test_name : Nil
    AMIME::Header::Unstructured
      .new("subject", "")
      .name
      .should eq "subject"
  end

  def test_body : Nil
    header = AMIME::Header::Unstructured.new "foo", "bar"
    header.body.should eq "bar"
    header.body = "baz"
    header.body.should eq "baz"
  end

  def test_to_s : Nil
    AMIME::Header::Unstructured
      .new("subject", "content")
      .to_s
      .should eq "subject: content"
  end

  def test_to_s_long_lines : Nil
    AMIME::Header::Unstructured
      .new("x-custom-header", "The quick brown fox jumped over the fence, he was a very very scary brown fox with a bushy tail")
      .to_s
      .should eq <<-TXT
        x-custom-header: The quick brown fox jumped over the fence, he was a very\r
         very scary brown fox with a bushy tail
        TXT
  end

  def test_only_printable_ascii_appears_in_headers : Nil
    AMIME::Header::Unstructured
      .new("x-test", "\x8F")
      .to_s
      .should match /[^:\x00-\x20\x80-\xFF]+: [^\x80-\xFF\r\n]+$/
  end

  def test_follows_general_structure : Nil
    AMIME::Header::Unstructured
      .new("x-test", "\x8F")
      .to_s
      .should match /^x-test: \=?.*?\?.*?\?.*?\?=$/
  end

  def test_encoded_words_include_charset_and_encoding : Nil
    header = AMIME::Header::Unstructured.new("x-test", "\x8F")
    header.charset = "iso-8859-1"
    header
      .to_s
      .should eq "x-test: =?iso-8859-1?Q?=8F?="
  end

  def test_encoded_words_are_used_to_represent_non_printable_ascii : Nil
    # Allows SPACE and TAB
    non_printable_bytes = [] of UInt8
    non_printable_bytes.concat (0x00_u8..0x08).to_a
    non_printable_bytes.concat (0x10_u8..0x19).to_a
    non_printable_bytes << 0x7F_u8

    non_printable_bytes.each do |byte|
      char = String.build(&.write_byte(byte))
      encoded_char = sprintf "=%02X", byte

      AMIME::Header::Unstructured
        .new("x-test", char)
        .to_s
        .should eq "x-test: =?UTF-8?Q?#{encoded_char}?="
    end
  end

  def test_encoded_words_are_used_to_encode8_bit_octets : Nil
    (0x80_u8..0xFF).each do |byte|
      char = String.build(&.write_byte(byte))
      encoded_char = sprintf "=%02X", byte

      header = AMIME::Header::Unstructured.new("x-test", char)
      header.charset = "iso-8859-1"

      header.to_s.should eq "x-test: =?iso-8859-1?Q?#{encoded_char}?="
    end
  end

  def test_are_no_longer_than_75_chars_per_line : Nil
    non_ascii_char = String.build(&.write_byte(143_u8))

    header = AMIME::Header::Unstructured.new("x-test", non_ascii_char)
    header.charset = "iso-8859-1"

    header.to_s.should eq "x-test: =?iso-8859-1?Q?=8F?="
  end

  def test_fwsp_is_used_when_encoder_returns_multiple_lines : Nil
    header = AMIME::Header::Unstructured.new "x-test", "\x8Fline_one_here\r\nline_two_here"
    header.charset = "iso-8859-1"

    header.to_s.should eq "x-test: =?iso-8859-1?Q?=8Fline=5Fone=5Fhere?=\r\n =?iso-8859-1?Q?line=5Ftwo=5Fhere?="
  end

  def test_language_information_appears_in_encoded_words : Nil
    header = AMIME::Header::Unstructured.new "subject", "go\x8Fbar"
    header.charset = "iso-8859-1"
    header.lang = "en"

    header.to_s.should eq "subject: =?iso-8859-1*en?Q?go=8Fbar?="
  end
end
