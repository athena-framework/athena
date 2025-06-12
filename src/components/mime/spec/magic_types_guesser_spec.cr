require "./abstract_types_guesser_test_case"
require "./spec_helper"

struct MagicTypesGuesserTest < AbstractTypesGuesserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::MagicTypesGuesser.new
  end

  def test_guess_with_known_extension : Nil
    assert_pending

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test.gif").should eq "image/gif"
  end

  def test_guess_with_leading_dash : Nil
    assert_pending

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/-test").should eq "image/gif"
  end

  def test_guess_without_extension : Nil
    assert_pending

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test").should eq "image/gif"
  end

  def test_guess_with_unknown_extension : Nil
    assert_pending

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/.unknownextension").should eq "application/octet-stream"
  end

  def test_guess_with_duplicated_file_type : Nil
    assert_pending

    self.guesser.guess_mime_type("#{__DIR__}/fixtures/test.docx").should eq "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  private def assert_pending : Nil
    pending! "Guesser is not supported" if {{ flag?("windows") && !flag?("gnu") }}
  end
end
