require "../spec_helper"

struct RFC2231EncoderTest < ASPEC::TestCase
  private RFC2245_TOKEN = Regex.new "^[\x21\x23-\x27\x2A\x2B\x2D\x2E\x30-\x39\x41-\x5A\x5E-\x7E]+$", options: :dollar_endonly

  def test_encoding_ascii_characters_produces_valid_token : Nil
    string = String.build do |io|
      (0x00_u8..0x7F_u8).each do |byte|
        io.write_byte byte
      end
    end

    encoded = AMIME::Encoder::RFC2231
      .new
      .encode(string)

    encoded.split("\r\n").each do |line|
      line.should match RFC2245_TOKEN
    end
  end

  def test_encoding_non_ascii_characters_produces_valid_token : Nil
    string = String.build do |io|
      (0x80_u8..0xFF_u8).each do |byte|
        io.write_byte byte
      end
    end

    encoded = AMIME::Encoder::RFC2231
      .new
      .encode(string)

    encoded.split("\r\n").each do |line|
      line.should match RFC2245_TOKEN
    end
  end

  def test_max_line_length_can_be_set : Nil
    AMIME::Encoder::RFC2231
      .new
      .encode("a" * 200, max_line_length: 75)
      .should eq <<-TXT
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
        TXT
  end

  def test_first_line_can_have_shorter_length : Nil
    AMIME::Encoder::RFC2231
      .new
      .encode("a" * 200, first_line_offset: 24, max_line_length: 72)
      .should eq <<-TXT
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\r
        aaaaaaaa
        TXT
  end

  @[TestWith(
    {"iso-2022-jp", "one.txt"},
    {"iso-8859-1", "one.txt"},
    {"utf-8", "one.txt"},
    {"utf-8", "two.txt"},
    {"utf-8", "three.txt"},
  )]
  def test_encoding_and_decoding_samples(encoding : String, file : String) : Nil
    encoder = AMIME::Encoder::RFC2231.new

    text = File.read "#{__DIR__}/../fixtures/samples/charsets/#{encoding}/#{file}"
    encoded_text = encoder.encode text, encoding

    # Encoded string should decode back to original string
    URI.decode(encoded_text.split("\r\n").join).should eq text
  end
end
