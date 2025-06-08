require "spec"
require "athena-spec"

require "../src/athena-mime"

# Override these tests as the native types guesser only works on the file extension.
# This'll be the default and only working guesser on MSVC windows.
module FileExtensionOnlyOverrides
  def test_guess_with_leading_dash : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/-test").should be_nil
  end

  def test_guess_without_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/test").should be_nil
  end

  def test_guess_with_unknown_extension : Nil
    self.guesser.guess_mime_type("#{__DIR__}/fixtures/mimetypes/.unknownextension").should be_nil
  end

  {% if flag?("windows") && !flag?("gnu") %}
    def test_guess_with_duplicated_file_type : Nil
      self.guesser.guess_mime_type("#{__DIR__}/fixtures/test.docx").should be_nil
    end
  {% end %}
end

ASPEC.run_all
