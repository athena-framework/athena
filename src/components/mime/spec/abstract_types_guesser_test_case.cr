require "./spec_helper"

abstract struct AbstractTypesGuesserTestCase < ASPEC::TestCase
  protected abstract def guesser : AMIME::TypesGuesserInterface

  def test_guess_directory : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The file '#{__DIR__}/fixtures/mimetypes/directory' does not exist or is not readable." do
      self.guesser.guess_mime_type "#{__DIR__}/fixtures/mimetypes/directory"
    end
  end

  def test_guess_incorrect_path : Nil
    expect_raises AMIME::Exception::InvalidArgument, "The file '#{__DIR__}/fixtures/mimetypes/not_here' does not exist or is not readable." do
      self.guesser.guess_mime_type "#{__DIR__}/fixtures/mimetypes/not_here"
    end
  end
end
