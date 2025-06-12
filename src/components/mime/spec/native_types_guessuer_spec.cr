require "./abstract_types_guesser_test_case"
require "./spec_helper"

struct NativeTypesGuesserTest < AbstractTypesGuesserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::NativeTypesGuesser.new
  end

  def test_guess_with_leading_dash : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/-test").should be_nil
  end

  def test_guess_without_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test").should be_nil
  end

  def test_guess_with_unknown_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/.unknownextension").should be_nil
  end

  def test_guess_with_duplicated_file_type : Nil
    # The MIME DB on windows CI doesn't know about this type, but works elsewhere
    pending! "Guesser is not supported" if {{ flag?("windows") && !flag?("gnu") }}

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/test.docx").should eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end
end
