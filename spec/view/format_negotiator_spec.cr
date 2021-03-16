require "../spec_helper"

struct FormatNegotiatorTest < ASPEC::TestCase
  @request_store : ART::RequestStore
  @request : HTTP::Request
  @negotiator : ART::View::FormatNegotiator
  @config : ART::Config::ContentNegotiation

  def initialize
    @request_store = ART::RequestStore.new
    @request = HTTP::Request.new "GET", "/"
    @request_store.request = @request
    @config = ART::Config::ContentNegotiation.new [] of ART::Config::ContentNegotiation::Rule

    @negotiator = ART::View::FormatNegotiator.new(
      @request_store,
      @config,
      {"json" => ["application/json;version=1.0"]}
    )
  end

  def test_best_no_config : Nil
    @negotiator.best("").should be_nil
  end

  def test_best_stop_exception : Nil
    self.add_rule
    self.add_rule stop: true

    expect_raises ART::Exceptions::StopFormatListener, "Stopping format listener." do
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
    priorities = ["text/html; charset=UTF-8", "html", "application/json"]
    self.add_rule priorities: priorities

    @negotiator.best("").should eq ANG::Accept.new "text/html;charset=utf-8"

    @request.headers["accept"] = "application/xhtml+xml, application/xml;q=0.9, */*;q=0.8"
    @negotiator.best("", {"html", "json"}).should eq ANG::Accept.new "application/xhtml+xml"
  end

  def test_best_fallback : Nil
    @request.headers["accept"] = "text/html"
    priorities = ["application/json"]
    self.add_rule priorities: priorities, fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "text/xml"
  end

  def test_best_format_from_mime_types_hash : Nil
    @request.headers["accept"] = "application/json;version=1.0"
    priorities = ["json"]
    self.add_rule priorities: priorities, fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "application/json;version=1.0"
  end

  def test_best_format : Nil
    @request.headers["accept"] = "application/json"
    priorities = ["json"]
    self.add_rule priorities: priorities, fallback_format: "xml"
    @negotiator.best("").should eq ANG::Accept.new "application/json"
  end

  private def add_rule(**args)
    @config.rules << ART::Config::ContentNegotiation::Rule.new **args
  end
end
