require "../spec_helper"

struct FormatNegotiatorTest < ASPEC::TestCase
  @request_store : ATH::RequestStore
  @request : ATH::Request
  @negotiator : ATH::View::FormatNegotiator
  @rules : Array(ATH::View::FormatNegotiator::Rule)

  def initialize
    @request_store = ATH::RequestStore.new
    @request = ATH::Request.new "GET", "/"
    @request_store.request = @request
    @rules = [] of ATH::View::FormatNegotiator::Rule

    @negotiator = ATH::View::FormatNegotiator.new(
      @request_store,
      @rules,
      {"json" => ["application/json;version=1.0"]}
    )
  end

  def test_best_no_config : Nil
    @negotiator.best("").should be_nil
  end

  def test_best_stop_exception : Nil
    self.add_rule
    self.add_rule stop: true

    expect_raises ATH::Exceptions::StopFormatListener, "Stopping format listener." do
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

  def test_best_undesired_path : Nil
    @request.headers["accept"] = "text/html"
    @request.path = "/user"
    self.add_rule priorities: ["html", "json"], fallback_format: "json", path: /^\/admin/
    @negotiator.best("").should be_nil
  end

  def test_best_undesired_method : Nil
    @request.headers["accept"] = "text/html"
    @request.method = "POST"
    self.add_rule priorities: ["html", "json"], fallback_format: "json", methods: ["GET"]
    @negotiator.best("").should be_nil
  end

  def test_best_undesired_host : Nil
    @request.headers["accept"] = "text/html"
    @request.headers["host"] = "app.domain.com"
    self.add_rule priorities: ["html", "json"], fallback_format: "json", host: /api\.domain\.com/
    @negotiator.best("").should be_nil
  end

  private def add_rule(**args)
    @rules << ATH::View::FormatNegotiator::Rule.new **args
  end
end
