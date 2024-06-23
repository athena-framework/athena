require "../spec_helper"

private def new_response_event
  new_response_event() { }
end

private def new_response_event(& : ATH::Request -> _)
  request = new_request
  yield request
  ATH::Events::Response.new request, ATH::Response.new
end

private def assert_headers(response : ATH::Response, origin : String = "https://example.com") : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-headers"].should eq "X-FOO"
  response.headers["access-control-allow-methods"].should eq "POST, GET"
  response.headers["access-control-allow-origin"].should eq origin
  response.headers["access-control-max-age"].should eq "123"
end

private def assert_headers_with_wildcard_config_without_request_headers(response : ATH::Response) : Nil
  response.headers["access-control-allow-credentials"]?.should be_nil
  response.headers["access-control-allow-headers"]?.should be_nil
  response.headers["access-control-allow-methods"].should eq "GET, POST, HEAD"
  response.headers["access-control-allow-origin"].should eq "https://example.com"
  response.headers["access-control-max-age"].should eq "123"
end

private EMPTY_CONFIG    = ATH::Listeners::CORS::Config.new
private WILDCARD_CONFIG = ATH::Listeners::CORS::Config.new(
  allow_credentials: false,
  allow_headers: %w(*),
  allow_origin: %w(*),
  expose_headers: %w(*),
  max_age: 123,
)
private CONFIG = ATH::Listeners::CORS::Config.new(
  allow_credentials: true,
  allow_headers: %w(X-FOO),
  allow_methods: %w(POST GET),
  allow_origin: ["https://example.com", /https:\/\/(?:api|app)\.example\.com/],
  expose_headers: %w(HEADER1 HEADER2),
  max_age: 123
)

describe ATH::Listeners::CORS do
  describe "#on_request - request" do
    it "without a configuration defined" do
      listener = ATH::Listeners::CORS.new
      event = new_request_event

      listener.on_request event

      event.response.should be_nil
      event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    it "without the origin header" do
      listener = ATH::Listeners::CORS.new EMPTY_CONFIG
      event = new_request_event

      listener.on_request event

      event.response.should be_nil
      event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    describe "preflight" do
      describe :defaults do
        it "should only set the default headers" do
          listener = ATH::Listeners::CORS.new EMPTY_CONFIG
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://example.com"
            request.headers.add "access-control-request-method", "GET"
          end

          listener.on_request event

          response = event.response.should_not be_nil
          response.headers["vary"].should eq "origin"
          response.headers["access-control-allow-methods"].should eq "GET, POST, HEAD"
          event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        end
      end

      it "with an unsupported request method" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "LINK"
        end

        listener.on_request event

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers response
      end

      it "with an unsupported request header" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-BAD"
        end

        expect_raises ATH::Exception::Forbidden, "Unauthorized header: 'X-BAD'" do
          listener.on_request event
        end

        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        event.response.should be_nil
      end

      it "with an invalid origin" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://admin.example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.on_request event

        response = event.response.should_not be_nil
        response.headers["vary"].should eq "origin"
        response.headers["access-control-allow-methods"].should eq "POST, GET"
        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
      end

      describe "proper request" do
        it "static origin" do
          listener = ATH::Listeners::CORS.new CONFIG
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://example.com"
            request.headers.add "access-control-request-method", "GET"
            request.headers.add "access-control-request-headers", "X-FOO"
          end

          listener.on_request event

          event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

          assert_headers event.response.should_not be_nil
        end

        it "regex origin" do
          listener = ATH::Listeners::CORS.new CONFIG
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://api.example.com"
            request.headers.add "access-control-request-method", "GET"
            request.headers.add "access-control-request-headers", "X-FOO"
          end

          listener.on_request event

          event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

          assert_headers event.response.should_not(be_nil), "https://api.example.com"
        end
      end

      it "without the access-control-request-headers header" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.on_request event

        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response.should_not be_nil
      end

      it "without the access-control-request-headers header and wildcard in allow_headers config" do
        listener = ATH::Listeners::CORS.new WILDCARD_CONFIG
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.on_request event

        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers_with_wildcard_config_without_request_headers event.response.should_not be_nil
      end
    end

    describe "non-preflight" do
      it "with an invalid domain" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.net"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.on_request event

        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        event.response.should be_nil
      end

      it "with a proper request" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_request_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.on_request event

        event.request.attributes.has?(ATH::Listeners::CORS::ALLOW_SET_ORIGIN).should be_true
        event.response.should be_nil
      end
    end
  end

  describe "#on_response - response" do
    describe "with a proper request" do
      it "static origin" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_response_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"

          request.attributes.set ATH::Listeners::CORS::ALLOW_SET_ORIGIN, true
        end

        listener.on_response event

        event.response.headers["access-control-allow-origin"].should eq "https://example.com"
        event.response.headers["access-control-allow-credentials"].should eq "true"
        event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
      end

      it "valid regex origin" do
        listener = ATH::Listeners::CORS.new CONFIG
        event = new_response_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://app.example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"

          request.attributes.set ATH::Listeners::CORS::ALLOW_SET_ORIGIN, true
        end

        listener.on_response event

        event.response.headers["access-control-allow-origin"].should eq "https://app.example.com"
        event.response.headers["access-control-allow-credentials"].should eq "true"
        event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
      end
    end

    it "that should not allow setting origin" do
      listener = ATH::Listeners::CORS.new CONFIG
      event = new_response_event do |request|
        request.method = "GET"
        request.headers.add "origin", "https://example.com"
        request.headers.add "access-control-request-method", "GET"
        request.headers.add "access-control-request-headers", "X-FOO"

        request.attributes.set ATH::Listeners::CORS::ALLOW_SET_ORIGIN, false
      end

      listener.on_response event

      event.response.headers.size.should eq 2
    end

    it "without a configuration defined" do
      listener = ATH::Listeners::CORS.new
      event = new_response_event

      listener.on_response event

      event.response.headers.size.should eq 2
    end
  end
end
