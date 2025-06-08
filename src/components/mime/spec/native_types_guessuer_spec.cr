require "./abstract_types_guesser_test_case"
require "./spec_helper"

struct NativeTypesGuesserTest < AbstractTypesGuesserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::NativeTypesGuesser.new
  end

  # Override these tests as the native types guesser only works on the file extension.

  def test_guess_with_leading_dash : Nil
    assert_supported!

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/-test").should be_nil
  end

  def test_guess_without_extension : Nil
    assert_supported!

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test").should be_nil
  end

  def test_guess_with_unknown_extension : Nil
    assert_supported!

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/.unknownextension").should be_nil
  end
end
