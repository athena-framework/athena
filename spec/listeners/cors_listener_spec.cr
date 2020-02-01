require "../spec_helper"

private struct MockCorsConfigResolver
  include ACF::ConfigurationResolverInterface

  def self.get_empty_config : ART::Config::CORS
    ART::Config::CORS.new
  end

  def self.get_config_with_wildcards : ART::Config::CORS
    ART::Config::CORS.from_yaml <<-YAML
      allow_credentials: true
      max_age: 123
      expose_headers: ["*"]
      allow_headers: ["*"]
      allow_origin: ["*"]
    YAML
  end

  def initialize(@config : ART::Config::CORS? = get_config); end

  def resolve(_type : ART::Config::CORS.class) : ART::Config::CORS?
    @config
  end

  def resolve(_type) : Nil
  end

  def resolve : ACF::Base
    ACF::Base.new
  end

  private def get_config : ART::Config::CORS
    ART::Config::CORS.from_yaml <<-YAML
      allow_credentials: true
      max_age: 123
      expose_headers:
        - HEADER1
        - HEADER2
      allow_headers:
        - X-FOO
      allow_origin:
        - https://example.com
      allow_methods:
        - POST
        - GET
    YAML
  end
end

private def new_request_event
  new_request_event { }
end

private def new_request_event(& : HTTP::Request -> _)
  request = new_request
  yield request
  ART::Events::Request.new request
end

private def new_response_event
  new_response_event() { }
end

private def new_response_event(& : HTTP::Request -> _)
  request = new_request
  yield request
  ART::Events::Response.new request, ART::Response.new
end

private def assert_headers(response : ART::Response) : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-headers"].should eq "X-FOO"
  response.headers["access-control-allow-methods"].should eq "POST, GET"
  response.headers["access-control-allow-origin"].should eq "https://example.com"
  response.headers["access-control-max-age"].should eq "123"
end

private def assert_headers_with_wildcard_config_without_request_headers(response : ART::Response) : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-headers"]?.should be_nil
  response.headers["access-control-allow-methods"].should eq "GET, POST, HEAD"
  response.headers["access-control-allow-origin"].should eq "https://example.com"
  response.headers["access-control-max-age"].should eq "123"
end

describe ART::Listeners::CORS do
  describe "#call - request" do
    it "without a configuration defined" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new nil
      event = new_request_event

      listener.call event, TracableEventDispatcher.new

      event.response.should be_nil
      event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    it "without the origin header" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_empty_config
      event = new_request_event

      listener.call event, TracableEventDispatcher.new

      event.response.should be_nil
      event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    describe "preflight" do
      describe :defaults do
        it "should only set the default headers" do
          listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_empty_config
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://example.com"
            request.headers.add "access-control-request-method", "GET"
          end

          listener.call event, TracableEventDispatcher.new

          response = event.response.should_not be_nil
          response.headers["vary"].should eq "origin"
          response.headers["access-control-allow-methods"].should eq "GET, POST, HEAD"
          event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        end
      end

      it "with an unsupported request method" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "LINK"
        end

        listener.call event, TracableEventDispatcher.new

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers response
      end

      it "with an unsupported request header" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-BAD"
        end

        expect_raises ART::Exceptions::Forbidden, "Unauthorized header: 'X-BAD'" do
          listener.call event, TracableEventDispatcher.new
        end

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        event.response.should be_nil
      end

      it "with a proper request" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, TracableEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response.should_not be_nil
      end

      it "without the access-control-request-headers header" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, TracableEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response.should_not be_nil
      end

      it "without the access-control-request-headers header and wildcard in allow_headers config" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_config_with_wildcards
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, TracableEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers_with_wildcard_config_without_request_headers event.response.should_not be_nil
      end
    end

    describe "non-preflight" do
      it "with an invalid domain" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.net"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, TracableEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        event.response.should be_nil
      end

      it "with a proper request" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, TracableEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_true
        event.response.should be_nil
      end
    end
  end

  describe "#call - response" do
    it "with a proper request" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
      event = new_response_event do |request|
        request.method = "GET"
        request.headers.add "origin", "https://example.com"
        request.headers.add "access-control-request-method", "GET"
        request.headers.add "access-control-request-headers", "X-FOO"

        request.attributes[Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN] = true
      end

      listener.call event, TracableEventDispatcher.new

      event.response.headers["access-control-allow-origin"].should eq "https://example.com"
      event.response.headers["access-control-allow-credentials"].should eq "true"
      event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
    end

    it "that should not allow setting origin" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
      event = new_response_event do |request|
        request.method = "GET"
        request.headers.add "origin", "https://example.com"
        request.headers.add "access-control-request-method", "GET"
        request.headers.add "access-control-request-headers", "X-FOO"

        request.attributes[Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN] = false
      end

      listener.call event, TracableEventDispatcher.new

      event.response.headers.should be_empty
    end

    it "without a configuration defined" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new nil
      event = new_response_event

      listener.call event, TracableEventDispatcher.new

      event.response.headers.should be_empty
    end
  end
end
