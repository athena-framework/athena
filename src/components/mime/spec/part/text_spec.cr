require "../spec_helper"

struct TextPartTest < ASPEC::TestCase
  def test_constructor : Nil
    p = AMIME::Part::Text.new "content"
    p.body.should eq "content"
    p.body_to_s.should eq "content"
    p.media_type.should eq "text"
    p.media_sub_type.should eq "plain"

    p = AMIME::Part::Text.new "content", sub_type: "html"
    p.media_type.should eq "text"
    p.media_sub_type.should eq "html"
  end

  def test_constructor_io : Nil
    io = IO::Memory.new "content"

    p = AMIME::Part::Text.new io
    p.body.should eq "content"
    p.body_to_s.should eq "content"
  end

  def test_constructor_real_file : Nil
    File.open "#{__DIR__}/../fixtures/content.txt", "r" do |file|
      p = AMIME::Part::Text.new file
      p.body.should eq "content"
      p.body_to_s.should eq "content"
    end
  end

  def test_constructor_file_part : Nil
    p = AMIME::Part::Text.new(AMIME::Part::File.new("#{__DIR__}/../fixtures/content.txt"))
    p.body.should eq "content"
    p.body_to_s.should eq "content"
  end

  def test_constructor_unknown_file : Nil
    expect_raises AMIME::Exception::InvalidArgument, "File is not readable." do
      AMIME::Part::Text.new(AMIME::Part::File.new("#{__DIR__}/../fixtures/")).body
    end
  end

  def test_headers : Nil
    p = AMIME::Part::Text.new "content"
    p.prepared_headers.should eq AMIME::Header::Collection.new(
      AMIME::Header::Parameterized.new("content-type", "text/plain", {"charset" => "UTF-8"}),
      AMIME::Header::Unstructured.new("content-transfer-encoding", "quoted-printable"),
    )

    p = AMIME::Part::Text.new "content", charset: "iso-8859-1"
    p.prepared_headers.should eq AMIME::Header::Collection.new(
      AMIME::Header::Parameterized.new("content-type", "text/plain", {"charset" => "iso-8859-1"}),
      AMIME::Header::Unstructured.new("content-transfer-encoding", "quoted-printable"),
    )
  end

  def test_encoding : Nil
    p = AMIME::Part::Text.new "content", encoding: "base64"
    p.prepared_headers.should eq AMIME::Header::Collection.new(
      AMIME::Header::Parameterized.new("content-type", "text/plain", {"charset" => "UTF-8"}),
      AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
    )
  end

  def ptest_custom_encoder_needs_to_be_registered_first : Nil
  end

  def ptest_override_custom_encoder : Nil
  end

  def ptest_custom_encoder : Nil
  end
end
