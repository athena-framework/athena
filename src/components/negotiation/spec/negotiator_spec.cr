require "./spec_helper"

struct NegotiatorTest < NegotiatorTestCase
  @negotiator : ANG::Negotiator

  def initialize
    @negotiator = ANG::Negotiator.new
  end

  def test_best_respects_quality : Nil
    accept = @negotiator.best "text/html,text/*;q=0.7", {"text/html;q=0.5", "text/plain;q=0.9"}
    accept = accept.should_not be_nil
    accept.should be_a ANG::Accept
    accept.media_range.should eq "text/plain"
  end

  def test_best_invalid_unstrict
    @negotiator.best("/qwer", {"foo/bar"}, false).should be_nil
  end

  def test_invalid_media_type : Nil
    ex = expect_raises ANG::Exceptions::InvalidMediaType, "Invalid media type: '/qwer'." do
      @negotiator.best "foo/bar", {"/qwer"}
    end

    ex.media_range.should eq "/qwer"
  end

  @[DataProvider("best_data_provider")]
  def test_best(header : String, priorities : Indexable(String), expected : Tuple(String, Hash(String, String) | Nil) | Nil) : Nil
    begin
      accept_header = @negotiator.best header, priorities
    rescue ex
      ex.should eq expected

      return
    end

    if accept_header.nil?
      expected.should be_nil

      return
    end

    accept_header.should be_a ANG::Accept

    expected = expected.should_not be_nil

    accept_header.media_range.should eq expected[0]
    accept_header.parameters.should eq(expected[1] || Hash(String, String).new)
  end

  def best_data_provider : Tuple
    rfc_header = "text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5"
    php_pear_header = "text/html,application/xhtml+xml,application/xml;q=0.9,text/*;q=0.7,*/*,image/gif; q=0.8, image/jpeg; q=0.6, image/*"

    {
      {"/qwer", {"f/g"}, nil},
      {"text/html", {"application/rss"}, nil},
      {rfc_header, {"text/html;q=0.4", "text/plain"}, {"text/plain", nil}},

      # See http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html.
      {rfc_header, {"text/html;level=1"}, {"text/html", {"level" => "1"}}},
      {rfc_header, {"text/html"}, {"text/html", nil}},
      {rfc_header, {"image/jpeg"}, {"image/jpeg", nil}},
      {rfc_header, {"text/html;level=2"}, {"text/html", {"level" => "2"}}},
      {rfc_header, {"text/html;level=3"}, {"text/html", {"level" => "3"}}},

      {"text/*;q=0.7, text/html;q=0.3, */*;q=0.5, image/png;q=0.4", {"text/html", "image/png"}, {"image/png", nil}},
      {"image/png;q=0.1, text/plain, audio/ogg;q=0.9", {"image/png", "text/plain", "audio/ogg"}, {"text/plain", nil}},
      {"image/png, text/plain, audio/ogg", {"baz/asdf"}, nil},
      {"image/png, text/plain, audio/ogg", {"audio/ogg"}, {"audio/ogg", nil}},
      {"image/png, text/plain, audio/ogg", {"YO/SuP"}, nil},
      {"text/html; charset=UTF-8, application/pdf", {"text/html; charset=UTF-8"}, {"text/html", {"charset" => "UTF-8"}}},
      {"text/html; charset=UTF-8, application/pdf", {"text/html"}, nil},
      {"text/html, application/pdf", {"text/html; charset=UTF-8"}, {"text/html", {"charset" => "UTF-8"}}},

      # PHP"s PEAR HTTP2 assertions I took from the other lib.
      {php_pear_header, {"image/gif", "image/png", "application/xhtml+xml", "application/xml", "text/html", "image/jpeg", "text/plain"}, {"image/png", nil}},
      {php_pear_header, {"image/gif", "application/xhtml+xml", "application/xml", "image/jpeg", "text/plain"}, {"application/xhtml+xml", nil}},
      {php_pear_header, {"image/gif", "application/xml", "image/jpeg", "text/plain"}, {"application/xml", nil}},
      {php_pear_header, {"image/gif", "image/jpeg", "text/plain"}, {"image/gif", nil}},
      {php_pear_header, {"text/plain", "image/png", "image/jpeg"}, {"image/png", nil}},
      {php_pear_header, {"image/jpeg", "image/gif"}, {"image/gif", nil}},
      {php_pear_header, {"image/png"}, {"image/png", nil}},
      {php_pear_header, {"audio/midi"}, {"audio/midi", nil}},
      {"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", {"application/rss+xml"}, {"application/rss+xml", nil}},

      # Case sensitiviy
      {"text/* ; q=0.3, TEXT/html ;Q=0.7, text/html ; level=1, texT/Html ;leVel = 2 ;q=0.4, */* ; q=0.5", {"text/html; level=2"}, {"text/html", {"level" => "2"}}},
      {"text/* ; q=0.3, text/html;Q=0.7, text/html ;level=1, text/html; level=2;q=0.4, */*;q=0.5", {"text/HTML; level=3"}, {"text/html", {"level" => "3"}}},

      # IE8
      {"image/jpeg, application/x-ms-application, image/gif, application/xaml+xml, image/pjpeg, application/x-ms-xbap, */*", {"text/html", "application/xhtml+xml"}, {"text/html", nil}},

      # wildcards with `+`
      {"application/vnd.api+json", {"application/json", "application/*+json"}, {"application/*+json", nil}},
      {"application/json;q=0.7, application/*+json;q=0.7", {"application/hal+json", "application/problem+json"}, {"application/hal+json", nil}},
      {"application/json;q=0.7, application/problem+*;q=0.7", {"application/hal+xml", "application/problem+xml"}, {"application/problem+xml", nil}},
      {php_pear_header, {"application/*+xml"}, {"application/*+xml", nil}},
      {"application/hal+json", {"application/ld+json", "application/hal+json", "application/xml", "text/xml", "application/json", "text/html"}, {"application/hal+json", nil}},
    }
  end

  def test_ordered_elements_exception_handling : Nil
    expect_raises ArgumentError, "The header string should not be empty." do
      @negotiator.ordered_elements ""
    end
  end

  @[DataProvider("test_ordered_elements_data_provider")]
  def test_ordered_elements(header : String, expected : Indexable(String)) : Nil
    elements = @negotiator.ordered_elements header

    elements.should be_a Array(ANG::Accept)

    expected.each_with_index do |element, idx|
      elements[idx].should be_a ANG::Accept
      element.should eq elements[idx].header
    end
  end

  def test_ordered_elements_data_provider : Tuple
    {
      {"/qwer", [] of String},                                                                                                                                                                    # Invalid
      {"text/html, text/xml", {"text/html", "text/xml"}},                                                                                                                                         # Ordered as given if no quality modifier
      {"text/html;q=0.3, text/html;q=0.7", {"text/html;q=0.7", "text/html;q=0.3"}},                                                                                                               # Ordered by quality modifier
      {"text/*;q=0.3, text/html;q=0.7, text/html;level=1, text/html;level=2;q=0.4, */*;q=0.5", {"text/html;level=1", "text/html;q=0.7", "*/*;q=0.5", "text/html;level=2;q=0.4", "text/*;q=0.3"}}, # Ordered by quality modifier; one without wins
    }
  end
end
