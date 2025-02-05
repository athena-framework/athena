require "../spec_helper"

struct FilePartTest < ASPEC::TestCase
  def test_content_type_known_extension : Nil
    AMIME::Part::File.new("#{__DIR__}/../fixtures/mimetypes/test.gif").content_type.should eq "image/gif"
  end

  def test_content_type_unknown_extension : Nil
    AMIME::Part::File.new("#{__DIR__}/../fixtures/mimetypes/.unknownextension").content_type.should eq "application/octet-stream"
  end

  def test_size : Nil
    AMIME::Part::File.new("#{__DIR__}/../fixtures/mimetypes/test.gif").size.should eq 35
  end

  def test_file_name_inferred : Nil
    AMIME::Part::File.new("#{__DIR__}/../fixtures/mimetypes/test.gif").filename.should eq "test.gif"
  end

  def test_file_name_explicit : Nil
    AMIME::Part::File.new("#{__DIR__}/../fixtures/mimetypes/test.gif", "image.gif").filename.should eq "image.gif"
  end
end
