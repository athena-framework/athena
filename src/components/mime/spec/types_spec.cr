require "./abstract_types_guesser_test_case"
require "./spec_helper"

private struct MockGuesser
  include AMIME::TypesGuesserInterface

  def supported? : Bool
    false
  end

  def guess_mime_type(path : String | Path) : String?
    fail "Should not have been called"
  end
end

struct MIMETypesTest < AbstractTypesGuesserTestCase
  protected def guesser : AMIME::TypesGuesserInterface
    AMIME::Types.new
  end

  def test_supported : Nil
    self.guesser.supported?.should be_true
  end

  def test_no_supported_guessers_raise : Nil
    guesser = self.guesser
    guesser.@guessers.clear

    expect_raises AMIME::Exception::Logic, "Unable to guess the MIME type as no guessers are available." do
      guesser.guess_mime_type "#{__DIR__}/fixtures/mimetypes/test"
    end
  end

  def test_extensions : Nil
    types = AMIME::Types.new
    types.extensions("application/mbox").should eq({"mbox"})
    types.extensions("application/postscript").should eq({"ai", "eps", "ps"})
    types.extensions("image/svg+xml").should contain "svg"
    types.extensions("image/svg").should contain "svg"
    types.extensions("application/whatever-athena").should be_empty
  end

  def test_mime_types : Nil
    types = AMIME::Types.new
    types.mime_types("mbox").should eq({"application/mbox"})
    types.mime_types("ai").should contain "application/postscript"
    types.mime_types("ps").should contain "application/postscript"
    types.mime_types("svg").should contain "image/svg+xml"
    types.mime_types("svg").should contain "image/svg"
    types.mime_types("athena").should be_empty
  end

  def test_custom_mimes_types : Nil
    types = AMIME::Types.new({
      "text/bar" => {"foo"},
      "text/baz" => {"foo", "moof"},
    })

    types.mime_types("foo").should contain "text/bar"
    types.mime_types("foo").should contain "text/baz"
    types.extensions("text/baz").should eq(["foo", "moof"])
  end
end
