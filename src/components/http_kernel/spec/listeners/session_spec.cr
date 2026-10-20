require "../spec_helper"

struct AHK::Listeners::SessionTest < ASPEC::TestCase
  @handler : AHTTP::Session::Storage::Handler::Memory

  def initialize
    @handler = AHTTP::Session::Storage::Handler::Memory.new
  end

  def tear_down : Nil
    AHTTP::Request.set_trusted_proxies [] of String, :none
  end

  def test_on_request_sets_a_lazily_created_session : Nil
    request = self.create_request

    self.create_listener.on_request AHK::Events::Request.new request

    request.has_session?.should be_true
    request.has_session?(true).should be_false

    request.session.started?.should be_false
    request.session.id.should be_empty
    request.has_session?(true).should be_true
  end

  def test_on_request_reads_the_session_id_from_the_cookie : Nil
    request = self.create_request cookie: "0123456789abcdef0123456789abcdef"

    self.create_listener.on_request AHK::Events::Request.new request

    request.session.id.should eq "0123456789abcdef0123456789abcdef"
  end

  def test_on_request_keeps_an_existing_session : Nil
    session = AHTTP::Session.new AHTTP::Session::Storage.new @handler

    request = self.create_request
    request.session = session

    self.create_listener.on_request AHK::Events::Request.new request

    request.session.should be session
  end

  def test_unused_session_is_not_created : Nil
    request = self.create_request
    response = self.handle self.create_listener, request

    request.has_session?(true).should be_false
    response.headers.cookies.should be_empty
    response.headers.has_cache_control_directive?("must-revalidate").should be_false
    response.headers.has_key?("expires").should be_false
  end

  def test_request_without_session : Nil
    request = self.create_request
    response = AHTTP::Response.new headers: ::HTTP::Headers{AHK::Listeners::Session::NO_AUTO_CACHE_CONTROL_HEADER => "true"}

    self.create_listener.on_response AHK::Events::Response.new request, response

    response.headers.cookies.should be_empty
    response.headers.has_key?(AHK::Listeners::Session::NO_AUTO_CACHE_CONTROL_HEADER).should be_false
  end

  def test_saves_the_session : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    self.handle self.create_listener, request do
      request.session.get("foo", String).should eq "bar"
      request.session.set "foo", "baz"
    end

    request.session.started?.should be_false

    request = self.create_request cookie: session_id
    self.handle self.create_listener, request do
      request.session.get("foo", String).should eq "baz"
    end
  end

  def test_cookie_set_for_a_new_session : Nil
    request = self.create_request
    response = self.handle self.create_listener, request do
      request.session.set "foo", "bar"
    end

    cookie = response.headers.cookies["athena_session_id"].should_not be_nil
    cookie.value.should eq request.session.id
    cookie.value.should_not be_empty
    cookie.path.should eq "/"
    cookie.domain.should be_nil
    cookie.secure.should be_false
    cookie.http_only.should be_true
    cookie.samesite.should eq ::HTTP::Cookie::SameSite::Lax
    cookie.expires.should be_nil
    cookie.max_age.should be_nil
  end

  def test_cookie_not_set_for_an_empty_session : Nil
    request = self.create_request
    response = self.handle self.create_listener, request do
      request.session.start
    end

    response.headers.cookies.should be_empty
  end

  def test_cookie_not_set_for_an_unchanged_session_id : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    response = self.handle self.create_listener, request do
      request.session.set "foo", "baz"
    end

    request.session.id.should eq session_id
    response.headers.cookies.should be_empty
  end

  def test_cookie_set_for_an_unknown_session_id : Nil
    request = self.create_request cookie: "0123456789abcdef0123456789abcdef"
    response = self.handle self.create_listener, request do
      request.session.set "foo", "bar"
    end

    session_id = request.session.id
    session_id.should_not eq "0123456789abcdef0123456789abcdef"
    response.headers.cookies["athena_session_id"].value.should eq session_id
  end

  def test_cookie_set_for_a_migrated_session : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    response = self.handle self.create_listener, request do
      request.session.migrate
    end

    new_session_id = request.session.id
    new_session_id.should_not eq session_id
    response.headers.cookies["athena_session_id"].value.should eq new_session_id
  end

  def test_cookie_cleared_for_an_invalidated_session : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    response = self.handle self.create_listener(cookie_path: "/path", cookie_domain: "example.com", cookie_secure: true, cookie_http_only: false, cookie_samesite: ::HTTP::Cookie::SameSite::Strict), request do
      request.session.invalidate
    end

    cookie = response.headers.cookies["athena_session_id"].should_not be_nil
    cookie.expired?.should be_true
    cookie.value.should be_empty
    cookie.path.should eq "/path"
    cookie.domain.should eq "example.com"
    cookie.secure.should be_true
    cookie.http_only.should be_false
    cookie.samesite.should eq ::HTTP::Cookie::SameSite::Strict
  end

  def test_cookie_not_cleared_for_a_session_with_data : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    response = self.handle self.create_listener, request do
      request.session.start
    end

    response.headers.cookies.should be_empty
  end

  def test_cookie_attributes : Nil
    request = self.create_request
    response = self.handle self.create_listener(cookie_path: "/path", cookie_domain: "example.com", cookie_secure: true, cookie_http_only: false, cookie_samesite: nil), request do
      request.session.set "foo", "bar"
    end

    cookie = response.headers.cookies["athena_session_id"].should_not be_nil
    cookie.path.should eq "/path"
    cookie.domain.should eq "example.com"
    cookie.secure.should be_true
    cookie.http_only.should be_false
    cookie.samesite.should be_nil
  end

  def test_cookie_secure_if_the_request_is_secure : Nil
    AHTTP::Request.set_trusted_proxies ["3.3.3.3"], :forwarded_proto

    request = self.create_request
    request.headers["x-forwarded-proto"] = "https"
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    response = self.handle self.create_listener, request do
      request.session.set "foo", "bar"
    end

    response.headers.cookies["athena_session_id"].secure.should be_true
  end

  def test_cookie_not_secure_if_disabled : Nil
    AHTTP::Request.set_trusted_proxies ["3.3.3.3"], :forwarded_proto

    request = self.create_request
    request.headers["x-forwarded-proto"] = "https"
    request.remote_address = Socket::IPAddress.v4 3, 3, 3, 3, port: 1

    response = self.handle self.create_listener(cookie_secure: false), request do
      request.session.set "foo", "bar"
    end

    response.headers.cookies["athena_session_id"].secure.should be_false
  end

  def test_cookie_expires_with_the_cookie_lifetime : Nil
    request = self.create_request
    response = self.handle self.create_listener(cookie_lifetime: 3600), request do
      request.session.set "foo", "bar"
    end

    cookie = response.headers.cookies["athena_session_id"].should_not be_nil
    cookie.max_age.should eq 3600.seconds
    cookie.expires.should_not(be_nil).should be_close Time.utc + 3600.seconds, 2.seconds
  end

  def test_cookie_expires_with_the_lifetime_of_a_migrated_session : Nil
    session_id = self.create_persisted_session

    request = self.create_request cookie: session_id
    response = self.handle self.create_listener(cookie_lifetime: 3600), request do
      request.session.migrate lifetime: 60
    end

    cookie = response.headers.cookies["athena_session_id"].should_not be_nil
    cookie.max_age.should eq 60.seconds
    cookie.expires.should_not(be_nil).should be_close Time.utc + 60.seconds, 2.seconds
  end

  def test_response_private_if_the_session_was_used : Nil
    request = self.create_request
    response = self.handle self.create_listener, request do
      request.session.has? "foo"
    end

    response.headers.has_cache_control_directive?("private").should be_true
    response.headers.has_cache_control_directive?("must-revalidate").should be_true
    response.headers.get_cache_control_directive("max-age").should eq "0"
    response.expires.should_not(be_nil).should be_close Time.utc, 2.seconds
  end

  def test_response_private_keeps_its_max_age : Nil
    response = AHTTP::Response.new
    response.set_private
    response.max_age = 600

    request = self.create_request
    self.handle self.create_listener, request, response do
      request.session.has? "foo"
    end

    response.headers.has_cache_control_directive?("public").should be_false
    response.headers.has_cache_control_directive?("private").should be_true
    response.headers.has_cache_control_directive?("must-revalidate").should be_true
    response.headers.get_cache_control_directive("max-age").should eq "600"
    response.expires.should_not(be_nil).should be_close Time.utc + 600.seconds, 2.seconds
  end

  def test_response_public_becomes_private_along_with_targeted_cache_control : Nil
    response = AHTTP::Response.new
    response.set_public
    response.max_age = 300
    response.headers["CDN-Cache-Control"] = "max-age=3600, stale-if-error=86400"
    response.headers["Cloudflare-CDN-Cache-Control"] = "max-age=7200"

    request = self.create_request
    self.handle self.create_listener, request, response do
      request.session.has? "foo"
    end

    response.headers["cache-control"].should eq "max-age=0, private, must-revalidate"
    response.headers["CDN-Cache-Control"].should eq "max-age=0, private, must-revalidate"
    response.headers["Cloudflare-CDN-Cache-Control"].should eq "max-age=0, private, must-revalidate"
  end

  def test_response_private_if_the_session_cookie_is_set : Nil
    session_id = self.create_persisted_session

    response = AHTTP::Response.new
    response.set_public
    response.max_age = 300

    request = self.create_request cookie: session_id
    self.handle self.create_listener, request, response do
      request.session.migrate true
    end

    response.headers.cookies["athena_session_id"].value.should eq request.session.id
    response.headers["cache-control"].should eq "max-age=0, private, must-revalidate"
  end

  def test_response_private_if_the_session_cookie_is_cleared : Nil
    session_id = self.create_persisted_session

    response = AHTTP::Response.new
    response.set_public
    response.max_age = 300

    request = self.create_request cookie: session_id
    self.handle self.create_listener, request, response do
      request.session.invalidate
    end

    response.headers.cookies["athena_session_id"].expired?.should be_true
    response.headers["cache-control"].should eq "max-age=0, private, must-revalidate"
  end

  def test_response_public_with_no_auto_cache_control_header : Nil
    response = AHTTP::Response.new
    response.set_public
    response.headers.add_cache_control_directive "s-maxage", "60"
    response.headers["CDN-Cache-Control"] = "max-age=3600"
    response.headers[AHK::Listeners::Session::NO_AUTO_CACHE_CONTROL_HEADER] = "true"

    request = self.create_request
    self.handle self.create_listener, request, response do
      request.session.has? "foo"
    end

    response.headers.has_cache_control_directive?("public").should be_true
    response.headers.has_cache_control_directive?("private").should be_false
    response.headers.has_cache_control_directive?("must-revalidate").should be_false
    response.headers.get_cache_control_directive("s-maxage").should eq "60"
    response.headers["CDN-Cache-Control"].should eq "max-age=3600"
    response.headers.has_key?("expires").should be_false
    response.headers.has_key?(AHK::Listeners::Session::NO_AUTO_CACHE_CONTROL_HEADER).should be_false
  end

  def test_stateless_session_usage_raises_in_debug : Nil
    request = self.create_request
    request.attributes.set "_stateless", true

    expect_raises AHK::Exception::UnexpectedSessionUsage, "Session was used while the request was declared stateless." do
      self.handle self.create_listener(debug: true), request do
        request.session.has? "foo"
      end
    end
  end

  def test_stateless_session_usage_logs_a_warning : Nil
    request = self.create_request
    request.attributes.set "_stateless", true

    ::Log.capture do |logs|
      self.handle self.create_listener, request do
        request.session.has? "foo"
      end

      logs.check :warn, "Session was used while the request was declared stateless."
    end
  end

  def test_stateless_without_session_usage : Nil
    request = self.create_request
    request.attributes.set "_stateless", true

    ::Log.capture do |logs|
      self.handle self.create_listener(debug: true), request

      logs.empty
    end
  end

  # Returns the ID of a persisted session with the attribute `foo` set to `"bar"`.
  private def create_persisted_session : String
    request = self.create_request
    self.handle self.create_listener, request do
      request.session.set "foo", "bar"
    end

    request.session.id
  end

  private def create_listener(*, debug : Bool = false, cookie_lifetime : Int32 = 0, **cookie_attributes) : AHK::Listeners::Session
    storage_factory = AHTTP::Session::Storage::Factory.new @handler, cookie_lifetime: cookie_lifetime

    AHK::Listeners::Session.new AHTTP::Session::Factory.new(AHTTP::RequestStore.new, storage_factory), debug, **cookie_attributes
  end

  private def create_request(*, cookie : String? = nil) : AHTTP::Request
    request = AHTTP::Request.new "GET", "/"
    request.headers["cookie"] = "athena_session_id=#{cookie}" if cookie
    request
  end

  private def handle(listener : AHK::Listeners::Session, request : AHTTP::Request, response : AHTTP::Response = AHTTP::Response.new) : AHTTP::Response
    self.handle(listener, request, response) { }
  end

  private def handle(listener : AHK::Listeners::Session, request : AHTTP::Request, response : AHTTP::Response = AHTTP::Response.new, &) : AHTTP::Response
    listener.on_request AHK::Events::Request.new request
    yield
    listener.on_response AHK::Events::Response.new request, response

    response
  end
end
