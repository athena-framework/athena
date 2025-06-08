require "./spec_helper"

abstract struct AbstractTypesGuesserTestCase < ASPEC::TestCase
  protected abstract def guesser : AMIME::TypesGuesserInterface

  def test_guess_with_leading_dash : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/-test").should eq "image/gif"
  end

  def test_guess_without_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test").should eq "image/gif"
  end

  def test_guess_directory : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The file '#{__DIR__}/fixtures/mimetypes/directory' does not exist or is not readable." do
      self.guesser.guess_mime_type "#{__DIR__}/fixtures/mimetypes/directory"
    end
  end

  def test_guess_with_known_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test.gif").should eq "image/gif"
  end

  def test_guess_with_unknown_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/.unknownextension").should eq "application/octet-stream"
  end

  def test_guess_with_duplicated_file_type : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/test.docx").should eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  def test_guess_incorrect_path : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The file '#{__DIR__}/fixtures/mimetypes/not_here' does not exist or is not readable." do
      self.guesser.guess_mime_type "#{__DIR__}/fixtures/mimetypes/not_here"
    end
  end
end
