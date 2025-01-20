require "./spec_helper"

struct ATH::RequestTest < ASPEC::TestCase
  def tear_down : Nil
    ATH::Request.set_trusted_hosts [] of Regex
    ATH::Request.set_trusted_proxies [] of String, :none
    ATH::Request.trusted_header_overrides.clear
  end

  # This spec tests the built-in `#hostname` method
  def test_hostname : Nil
    request = ATH::Request.new "GET", "/"
    request.hostname.should be_nil

    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "www.domain.com"}
    request.hostname.should eq "www.domain.com"

    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "www.domain.com:8080"}
    request.hostname.should eq "www.domain.com"

    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "[::1]:8080"}
    request.hostname.should eq "::1"
  end

  def test_content_type_format_present : Nil
    ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "content-type" => "application/json",
    }).content_type_format.should eq "json"
  end

  def test_content_type_format_missing : Nil
    ATH::Request.new("GET", "/").content_type_format.should be_nil
  end

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
      {"form", {"application/x-www-form-urlencoded", "multipart/form-data"}},
    }
  end

  def test_trusted_proxy_conflict : Nil
    ATH::Request.set_trusted_proxies ["3.3.3.3"], ATH::Request::ProxyHeader[:forwarded, :forwarded_proto]

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "forwarded"         => "proto=http",
      "x-forwarded-proto" => "https",
    })
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    expect_raises ATH::Exception::ConflictingHeaders, "The request has both a trusted 'forwarded' header and a trusted 'x-forwarded-proto' header, conflicting with each other. You should either configure your proxy to remove one of them, or configure your project to distrust the offending one." do
      request.secure?
    end
  end

  def test_trusted_proxies_cache : Nil
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-for"   => "1.1.1.1, 2.2.2.2",
      "x-forwarded-proto" => "https",
    })
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    request.secure?.should be_false

    ATH::Request.set_trusted_proxies ["3.3.3.3", "2.2.2.2"], ATH::Request::ProxyHeader[:forwarded_for, :forwarded_host, :forwarded_port, :forwarded_proto]

    request.secure?.should be_true

    # Cache must not be hit due to change in header
    request.headers["x-forwarded-proto"] = "http"
    request.secure?.should be_false
  end

  def test_trusted_proxies_forwarded_for : Nil
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-for"   => "1.1.1.1, 2.2.2.2",
      "x-forwarded-host"  => "foo.example.com:1234, real.example.com:8080",
      "x-forwarded-proto" => "https",
      "x-forwarded-port"  => "443",
    })
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    # No trusted proxies
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Disabling proxy trusting
    ATH::Request.set_trusted_proxies [] of String, :forwarded_for
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Request is from non trusted proxy
    ATH::Request.set_trusted_proxies ["2.2.2.2"], :forwarded_for
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Trusted proxy
    ATH::Request.set_trusted_proxies ["3.3.3.3", "2.2.2.2"], ATH::Request::ProxyHeader[:forwarded_for, :forwarded_host, :forwarded_port, :forwarded_proto]
    request.from_trusted_proxy?.should be_true
    request.host.should eq "foo.example.com"
    request.port.should eq 443
    request.secure?.should be_true

    # Trusted proxy
    ATH::Request.set_trusted_proxies ["3.3.3.4", "2.2.2.2"], ATH::Request::ProxyHeader[:forwarded_for, :forwarded_host, :forwarded_port, :forwarded_proto]
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Alternate proto header values
    ATH::Request.set_trusted_proxies ["3.3.3.3"], :forwarded_proto
    request.headers["x-forwarded-proto"] = "ssl"
    request.secure?.should be_true

    request.headers["x-forwarded-proto"] = "https, http"
    request.secure?.should be_true
  end

  def test_trusted_proxies_forwarded : Nil
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"      => "example.com",
      "forwarded" => "for=1.1.1.1, host=foo.example.com:8080, proto=https, for=2.2.2.2, host=real.example.com:8080",
    })
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    # No trusted proxies
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Disabling proxy trusting
    ATH::Request.set_trusted_proxies [] of String, :forwarded
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Request is from non trusted proxy
    ATH::Request.set_trusted_proxies ["2.2.2.2"], :forwarded
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Trusted proxy
    ATH::Request.set_trusted_proxies ["3.3.3.3", "2.2.2.2"], :forwarded
    request.from_trusted_proxy?.should be_true
    request.host.should eq "foo.example.com"
    request.port.should eq 8080
    request.secure?.should be_true

    # Trusted proxy
    ATH::Request.set_trusted_proxies ["3.3.3.4", "2.2.2.2"], :forwarded
    request.from_trusted_proxy?.should be_false
    request.host.should eq "example.com"
    request.port.should eq 80
    request.secure?.should be_false

    # Alternate proto header values
    ATH::Request.set_trusted_proxies ["3.3.3.3"], :forwarded
    request.headers["forwarded"] = "proto=ssl"
    request.secure?.should be_true

    request.headers["forwarded"] = "proto=https, proto=http"
    request.secure?.should be_true
  end

  @[TestWith(
    { %(a#{".a"*40_000}) },
    {":" * 101}
  )]
  def test_very_long_hosts(host : String) : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => host}
    request.host.should eq host
  end

  @[TestWith(
    {".a", false, nil, nil},
    {"a..", false, nil, nil},
    {"a.", true, nil, nil},
    {"é", false, nil, nil},
    {"[::1]", true, nil, nil},
    {"[::1]:80", true, "[::1]", 80},
    {"." * 101, false, nil, nil},
  )]
  def test_host_valididy(host : String, is_valid : Bool, expected_host : String?, expected_port : Int32?) : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{"host" => host}

    if is_valid
      request.host.should eq expected_host || host

      if expected_port
        request.port.should eq expected_port
      end
    else
      expect_raises ATH::Exception::SuspiciousOperation, "Invalid Host: " do
        request.host
      end
    end
  end

  def test_trusted_host_localhost : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], :all

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "forwarded"        => "host=localhost:8080",
      "x-forwarded-host" => "localhost:8080",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.from_trusted_proxy?.should be_true
    request.host.should eq "localhost"
    request.port.should eq 8080
  end

  def test_trusted_host_ipv6 : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], :all

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "forwarded"        => "host=\"[::1]:443\"",
      "x-forwarded-host" => "[::1]:443",
      "x-forwarded-port" => "443",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.from_trusted_proxy?.should be_true
    request.host.should eq "[::1]"
    request.port.should eq 443
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
    ATH::Request.new("GET", "/").port.should eq 80
  end

  @[TestWith(
    domain: {"test.com:90", 90},
    ipv4: {"127.0.0.1:90", 90},
    ipv6: {"[::1]:90", 90},
    no_port: {"test.com", 80},
  )]
  def test_port(host : String, port : Int32?) : Nil
    ATH::Request.new("GET", "/", headers: HTTP::Headers{"host" => host}).port.should eq port
  end

  def test_port_trusted_port : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], :forwarded_port

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"             => "example.com",
      "forwarded"        => "host=localhost:8080",
      "x-forwarded-port" => "8080",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.port.should eq 8080

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"             => "example.com",
      "forwarded"        => "host=localhost",
      "x-forwarded-port" => "80",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.port.should eq 80

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "forwarded"         => "host=\"[::1]\"",
      "x-forwarded-proto" => "https",
      "x-forwarded-port"  => "443",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.port.should eq 443
  end

  def test_port_trusted_does_not_default_to_0 : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], :forwarded_for

    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"             => "localhost",
      "x-forwarded-host" => "test.example.com",
      "x-forwarded-port" => "",
    })
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1

    request.port.should eq 80
  end

  def test_port_trusted_proxies_none_set : Nil
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "https",
      "x-forwarded-port"  => "443",
    })

    # Ignored without trusted proxy
    request.port.should eq 80
  end

  def test_port_trusted_proxies_proto_port_set : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "https",
      "x-forwarded-port"  => "8443",
    })

    # Falls back on scheme on untrusted connection
    request.port.should eq 80

    # Uses proxy value if trusted
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 8443
  end

  def test_port_trusted_proxies_proto_set_https : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "https",
    })

    # Falls back on scheme on untrusted connection
    request.port.should eq 80

    # With only proto, falls back on default port for this scheme
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 443
  end

  def test_port_trusted_proxies_proto_set_http : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "http",
    })

    # Falls back on scheme on untrusted connection
    request.port.should eq 80

    # With only proto, falls back on default port for this scheme
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 80
  end

  def test_port_trusted_proxies_proto_on : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "On",
    })

    # Falls back on scheme on untrusted connection
    request.port.should eq 80

    # With only proto, falls back on default port for this scheme
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 443
  end

  def test_port_trusted_proxies_proto_one : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "1",
    })

    # Falls back on scheme on untrusted connection
    request.port.should eq 80

    # With only proto, falls back on default port for this scheme
    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 443
  end

  def test_port_trusted_proxies_proto_invalid : Nil
    ATH::Request.set_trusted_proxies ["1.1.1.1"], ATH::Request::ProxyHeader[:forwarded_proto, :forwarded_port]
    request = ATH::Request.new("GET", "/", headers: HTTP::Headers{
      "host"              => "example.com",
      "x-forwarded-proto" => "foo",
    })

    request.remote_address = Socket::IPAddress.v4 1, 1, 1, 1, port: 1
    request.port.should eq 80
  end

  def test_proxy_header_header_default : Nil
    ATH::Request::ProxyHeader::FORWARDED_PROTO.header.should eq "x-forwarded-proto"
  end

  def test_proxy_header_header_override : Nil
    ATH::Request.override_trusted_header :forwarded_proto, "foo-proto"

    ATH::Request::ProxyHeader::FORWARDED_PROTO.header.should eq "foo-proto"
  end

  def test_truested_host_not_set : Nil
    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{
      "host" => "evil.com",
    }

    request.host.should eq "evil.com"
  end

  def test_truested_host_untrusted : Nil
    # Add trusted domain, including subdomains
    ATH::Request.set_trusted_hosts([/^([a-z]{9}\.)?trusted\.com$/])

    request = ATH::Request.new "GET", "/", headers: HTTP::Headers{
      "host" => "evil.com",
    }

    # Untrusted host
    expect_raises ATH::Exception::SuspiciousOperation, "Untrusted Host: 'evil.com'" do
      request.host
    end
  end

  def test_truested_host_trusted : Nil
    # Add trusted domain, including subdomains
    ATH::Request.set_trusted_hosts([/^([a-z]{9}\.)?trusted\.com$/])

    request = ATH::Request.new "GET", "/"

    # Trusted host
    request.headers["host"] = "trusted.com"
    request.host.should eq "trusted.com"
    request.port.should eq 80

    request.headers["host"] = "trusted.com:8080"
    request.host.should eq "trusted.com"
    request.port.should eq 8080

    request.headers["host"] = "subdomain.trusted.com:8080"
    request.host.should eq "subdomain.trusted.com"
  end

  def test_truested_host_special_characters : Nil
    ATH::Request.set_trusted_hosts([/localhost(\.local){0,1}#,example.com/, /localhost/])

    request = ATH::Request.new "GET", "/"

    request.headers["host"] = "localhost"
    request.host.should eq "localhost"
  end

  def test_request_data : Nil
    request = ATH::Request.new "GET", "/", body: "foo=bar&biz=baz"
    params = request.request_data
    params.should eq p = URI::Params.new({"foo" => ["bar"], "biz" => ["baz"]})
    request.request_data.should eq p
  end
end
