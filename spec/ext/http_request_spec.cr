require "../spec_helper"

struct HTTP::RequestTest < ASPEC::TestCase
  @[DataProvider("mime_type_provider")]
  def test_mime_type(format : String, mime_types : Indexable(String)) : Nil
    request = HTTP::Request.new "GET", "/"
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
    request = HTTP::Request.new "GET", "/"
    request.request_format.should eq "json"

    request.request_format("html").should eq "html"
    request.request_format("json").should eq "json"

    request = HTTP::Request.new "GET", "/"
    request.request_format(nil).should be_nil

    request = HTTP::Request.new "GET", "/"
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
    HTTP::Request.new("GET", "/").safe?.should be_true
    HTTP::Request.new("HEAD", "/").safe?.should be_true
    HTTP::Request.new("OPTIONS", "/").safe?.should be_true
    HTTP::Request.new("TRACE", "/").safe?.should be_true
    HTTP::Request.new("POST", "/").safe?.should be_false
    HTTP::Request.new("PUT", "/").safe?.should be_false
  end
end
