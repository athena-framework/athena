require "../spec_helper"

private class MockRequestMatcher
  include ATH::RequestMatcher::Interface

  def initialize(@matches : Bool); end

  def matches?(request : ATH::Request) : Bool
    @matches
  end
end

struct FormatNegotiatorTest < ASPEC::TestCase
  @request_store : ATH::RequestStore
  @request : ATH::Request
  @negotiator : ATH::View::FormatNegotiator

  def initialize
    @request_store = ATH::RequestStore.new
    @request = ATH::Request.new "GET", "/"
    @request_store.request = @request

    @negotiator = ATH::View::FormatNegotiator.new(
      @request_store,
      {"json" => ["application/json;version=1.0"]}
    )
  end

  def test_best_no_config : Nil
    @negotiator.best("").should be_nil
  end

  def test_best_stop_exception : Nil
    self.add_rule false
    self.add_rule stop: true

    expect_raises ATH::Exception::StopFormatListener, "Stopping format listener." do
      @negotiator.best ""
    end
  end

  def test_fallback_format : Nil
    self.add_rule
    @negotiator.best("").should be_nil

    self.add_rule fallback_format: "html"
    @negotiator.best("").should eq ANG::Accept.new "text/html"
  end

  def test_fallback_format_priorities : Nil
    self.add_rule priorities: ["json", "xml"], fallback_format: nil
    @negotiator.best("").should be_nil

    self.add_rule priorities: ["json", "xml"], fallback_format: "json"
    @negotiator.best("").should eq ANG::Accept.new "application/json"
  end

  def test_best : Nil
    @request.headers["accept"] = "application/xhtml+xml, text/html, application/xml;q=0.9, */*;q=0.8"
    priorities = ["text/html; charset=utf-8", "html", "application/json"]
    self.add_rule priorities: priorities

    @negotiator.best("").should eq ANG::Accept.new "text/html;charset=utf-8"

    @request.headers["accept"] = "application/xhtml+xml, application/xml;q=0.9, */*;q=0.8"
    @negotiator.best("", {"html", "json"}).should eq ANG::Accept.new "application/xhtml+xml"
  end

  def test_best_fallback : Nil
    @request.headers["accept"] = "text/html"
    self.add_rule priorities: ["application/json"], fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "text/xml"
  end

  def test_best_format_from_mime_types_hash : Nil
    @request.headers["accept"] = "application/json;version=1.0"
    self.add_rule priorities: ["json"], fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "application/json;version=1.0"
  end

  def test_best_format : Nil
    @request.headers["accept"] = "application/json"
    self.add_rule priorities: ["json"], fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "application/json"
  end

  def test_best_with_prefer_extension : Nil
    priorities = ["text/html", "application/json"]
    self.add_rule priorities: priorities, prefer_extension: true

    @request.path = "/file.json"

    # Without extension mime-type in accept header

    @request.headers["accept"] = "text/html; q=1.0"
    @negotiator.best("").should eq ANG::Accept.new "application/json"

    # With low q extension mime-type in accept header

    @request.headers["accept"] = "text/html; q=1.0, application/json; q=0.1"
    @negotiator.best("").should eq ANG::Accept.new "application/json"
  end

  def test_best_with_prefer_extension_and_unknown_extension : Nil
    priorities = ["text/html", "application/json"]
    self.add_rule priorities: priorities, prefer_extension: true

    @request.path = "/file.123456789"

    # Without extension mime-type in accept header

    @request.headers["accept"] = "text/html, application/json"
    @negotiator.best("").should eq ANG::Accept.new "text/html"
  end

  private def add_rule(match : Bool = true, **args)
    rule = ATH::View::FormatNegotiator::Rule.new **args
    matcher = MockRequestMatcher.new match

    @negotiator.add matcher, rule
  end
end
