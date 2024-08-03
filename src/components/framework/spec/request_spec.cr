require "./spec_helper"

struct ATH::RequestTest < ASPEC::TestCase
  def test_hostname : Nil
    request = ATH::Request.new "GET", "/"
    request.hostname.should be_nil

    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "www.domain.com"}
    request.hostname.should eq "www.domain.com"

    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "www.domain.com:8080"}
    request.hostname.should eq "www.domain.com"
  end

  # def test_hostname_trusted : Nil
  # end

  @[DataProvider("mime_type_provider")]
  def test_mime_type(format : String, mime_types : Indexable(String)) : Nil
    request = ATH::Request.new "GET", "/"
    mime_types.each do |mt|
      request.format(mt).should eq format
    end

    request.class.register_format format, mime_types

    mime_types.each do |mt|
      request.format(mt).should eq format

      if !format.nil?
        mime_types[0].should eq request.mime_type format
      end
    end
  end

  def test_request_format : Nil
    request = ATH::Request.new "GET", "/"
    request.request_format.should eq "json"

    request.request_format("html").should eq "html"
    request.request_format("json").should eq "json"

    request = ATH::Request.new "GET", "/"
    request.request_format(nil).should be_nil

    request = ATH::Request.new "GET", "/"
    request.request_format = "foo"
    request.request_format.should eq "foo"
  end

  def mime_type_provider : Tuple
    {
      {"txt", {"text/plain"}},
      {"js", {"application/javascript", "application/x-javascript", "text/javascript"}},
      {"css", {"text/css"}},
      {"json", {"application/json", "application/x-json"}},
      {"jsonld", {"application/ld+json"}},
      {"xml", {"text/xml", "application/xml", "application/x-xml"}},
      {"rdf", {"application/rdf+xml"}},
      {"atom", {"application/atom+xml"}},
    }
  end

  def test_safe? : Nil
    ATH::Request.new("GET", "/").safe?.should be_true
    ATH::Request.new("HEAD", "/").safe?.should be_true
    ATH::Request.new("OPTIONS", "/").safe?.should be_true
    ATH::Request.new("TRACE", "/").safe?.should be_true
    ATH::Request.new("POST", "/").safe?.should be_false
    ATH::Request.new("PUT", "/").safe?.should be_false
  end

  def test_port_no_host_header : Nil
    ATH::Request.new("GET", "/").port.should be_nil
  end

  @[TestWith(
    domain: {"test.com:90", 90},
    ipv4: {"127.0.0.1:90", 90},
    ipv6: {"[::1]:90", 90},
    no_port: {"test.com", nil},
  )]
  def test_port(host : String, port : Int32?) : Nil
    ATH::Request.new("GET", "/", headers: HTTP::Headers{"host" => host}).port.should eq port
  end
end
