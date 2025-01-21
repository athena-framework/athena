require "../spec_helper"

struct DataPartTest < ASPEC::TestCase
  def test_constructor : Nil
    p = AMIME::Part::Data.new "content"
    p.body.should eq "content"
    p.body_to_s.should eq Base64.encode("content")
    p.media_type.should eq "application"
    p.media_sub_type.should eq "octet-stream"

    p = AMIME::Part::Data.new "content", content_type: "text/html"
    p.media_type.should eq "text"
    p.media_sub_type.should eq "html"
  end

  def test_constructor_io : Nil
    io = IO::Memory.new "content"

    p = AMIME::Part::Data.new io
    p.body.should eq "content"
    p.body_to_s.should eq Base64.encode("content")
  end

  def test_constructor_real_file : Nil
    File.open "#{__DIR__}/../fixtures/content.txt", "r" do |file|
      p = AMIME::Part::Data.new file
      p.body.should eq "content"
      p.body_to_s.should eq Base64.encode("content")
    end
  end

  def test_constructor_file_part : Nil
    p = AMIME::Part::Data.new(AMIME::Part::File.new("#{__DIR__}/../fixtures/content.txt"))
    p.body.should eq "content"
    p.body_to_s.should eq Base64.encode("content")
  end

  def test_prepared_headers : Nil
    AMIME::Part::Data
      .new("content")
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "application/octet-stream"),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "attachment"),
      )
  end

  def test_prepared_headers_image : Nil
    AMIME::Part::Data
      .new("content", "photo.jpg", "text/html")
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "text/html", {"name" => "photo.jpg"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "attachment", {"name" => "photo.jpg", "filename" => "photo.jpg"}),
      )
  end

  def test_prepared_headers_as_inline : Nil
    AMIME::Part::Data
      .new("content", "photo.jpg", "text/html")
      .as_inline
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "text/html", {"name" => "photo.jpg"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "inline", {"name" => "photo.jpg", "filename" => "photo.jpg"}),
      )
  end

  def test_prepared_headers_as_inline_with_cid : Nil
    part = AMIME::Part::Data.new("content", "photo.jpg", "text/html").as_inline
    content_id = part.content_id

    part
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "text/html", {"name" => "photo.jpg"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "inline", {"name" => "photo.jpg", "filename" => "photo.jpg"}),
        AMIME::Header::Identification.new("content-id", content_id)
      )
  end

  def test_from_path : Nil
    part = AMIME::Part::Data.from_path file = "#{__DIR__}/../fixtures/mimetypes/test.gif"
    content = File.read file

    part.body.should eq content
    part.body_to_s.should eq Base64.encode(content)
    part.media_type.should eq "image"
    part.media_sub_type.should eq "gif"

    part
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "image/gif", {"name" => "test.gif"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "attachment", {"name" => "test.gif", "filename" => "test.gif"}),
      )
  end

  def test_from_path_with_meta : Nil
    part = AMIME::Part::Data.from_path file = "#{__DIR__}/../fixtures/mimetypes/test.gif", "photo.gif", "image/jpeg"
    content = File.read file

    part.body.should eq content
    part.body_to_s.should eq Base64.encode(content)
    part.media_type.should eq "image"
    part.media_sub_type.should eq "jpeg"

    part
      .prepared_headers
      .should eq AMIME::Header::Collection.new(
        AMIME::Header::Parameterized.new("content-type", "image/jpeg", {"name" => "photo.gif"}),
        AMIME::Header::Unstructured.new("content-transfer-encoding", "base64"),
        AMIME::Header::Parameterized.new("content-disposition", "attachment", {"name" => "photo.gif", "filename" => "photo.gif"}),
      )
  end

  def test_has_content_id : Nil
    part = AMIME::Part::Data.new "content"
    part.has_content_id?.should be_false
    part.content_id
    part.has_content_id?.should be_true
  end

  def test_set_content_id : Nil
    part = AMIME::Part::Data.new "content"
    part.content_id = "test@test"
    part.content_id.should eq "test@test"
  end

  def test_set_content_id_invalid : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The 'test' CID is invalid as it does not contain an '@' symbol." do
      AMIME::Part::Data.new("content").content_id = "test"
    end
  end

  def test_filename : Nil
    part = AMIME::Part::Data.new "content"
    part.filename.should be_nil

    part = AMIME::Part::Data.new "content", "foo.txt"
    part.filename.should eq "foo.txt"
  end

  def test_content_type : Nil
    part = AMIME::Part::Data.new "content"
    part.content_type.should eq "application/octet-stream"

    part = AMIME::Part::Data.new "content", content_type: "application/pdf"
    part.content_type.should eq "application/pdf"
  end
end
