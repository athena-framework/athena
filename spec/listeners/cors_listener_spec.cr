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
      allow_methods: ["*"]
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

private def new_event(event : AED::Event.class = ART::Events::Request)
  new_event(event) { }
end

private def new_event(event : AED::Event.class = ART::Events::Request, &)
  request = new_request
  response = new_response
  ctx = HTTP::Server::Context.new request, response
  yield ctx
  event.new ctx
end

private class MockEventDispatcher
  include Athena::EventDispatcher::EventDispatcherInterface

  def add_listener(event : AED::Event.class, listener : AED::EventListenerType, priority : Int32 = 0) : Nil
  end

  def dispatch(event : AED::Event) : Nil
  end

  def listeners(event : AED::Event.class | Nil = nil) : Array(AED::EventListener)
    [] of AED::EventListener
  end

  def listener_priority(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Int32?
  end

  def has_listeners?(event : AED::Event.class | Nil = nil) : Bool
    false
  end

  def remove_listener(event : AED::Event.class, listener : AED::EventListenerInterface.class) : Nil
  end

  def remove_listener(event : AED::Event.class, listener : AED::EventListenerType) : Nil
  end
end

private def assert_headers(response : HTTP::Server::Response) : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-headers"].should eq "X-FOO"
  response.headers["access-control-allow-methods"].should eq "POST, GET"
  response.headers["access-control-allow-origin"].should eq "https://example.com"
  response.headers["access-control-max-age"].should eq "123"
end

private def assert_headers_with_wildcard_config_without_request_headers(response : HTTP::Server::Response) : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-methods"].should eq "*"
  response.headers["access-control-allow-origin"].should eq "https://example.com"
  response.headers["access-control-max-age"].should eq "123"
end

describe ART::Listeners::CORS do
  describe "#call - request" do
    it "without a configuration defined" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new nil
      event = new_event

      listener.call event, MockEventDispatcher.new

      event.response.headers.should be_empty
      event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    it "without the origin header" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_empty_config
      event = new_event

      listener.call event, MockEventDispatcher.new

      event.response.headers.should be_empty
      event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    describe "preflight" do
      describe :defaults do
        it "should only set the vary header" do
          listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_empty_config
          event = new_event do |ctx|
            ctx.request.method = "OPTIONS"
            ctx.request.headers.add "origin", "https://example.com"
            ctx.request.headers.add "access-control-request-method", "GET"
          end

          listener.call event, MockEventDispatcher.new

          event.response.headers["vary"].should eq "origin"
          event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        end
      end

      it "with an unsupported request method" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "OPTIONS"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "LINK"
        end

        listener.call event, MockEventDispatcher.new

        event.response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response
      end

      it "with an unsupported request header" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "OPTIONS"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "GET"
          ctx.request.headers.add "access-control-request-headers", "X-BAD"
        end

        expect_raises ART::Exceptions::Forbidden, "Unauthorized header: 'X-BAD'" do
          listener.call event, MockEventDispatcher.new
        end

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response
      end

      it "with a proper request" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "OPTIONS"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "GET"
          ctx.request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, MockEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response
      end

      it "without the access-control-request-headers header" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "OPTIONS"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, MockEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response
      end

      it "without the access-control-request-headers header and wildcard in allow_headers config" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_config_with_wildcards
        event = new_event do |ctx|
          ctx.request.method = "OPTIONS"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, MockEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers_with_wildcard_config_without_request_headers event.response
      end
    end

    describe "non-preflight" do
      it "with an invalid domain" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "GET"
          ctx.request.headers.add "origin", "https://example.net"
          ctx.request.headers.add "access-control-request-method", "GET"
          ctx.request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, MockEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        event.response.headers.should be_empty
      end

      it "with a proper request" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_event do |ctx|
          ctx.request.method = "GET"
          ctx.request.headers.add "origin", "https://example.com"
          ctx.request.headers.add "access-control-request-method", "GET"
          ctx.request.headers.add "access-control-request-headers", "X-FOO"
        end

        listener.call event, MockEventDispatcher.new

        event.request.attributes.has_key?(Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN).should be_true
        event.response.headers.should be_empty
      end
    end
  end

  describe "#call - response" do
    it "with a proper request" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
      event = new_event(ART::Events::Response) do |ctx|
        ctx.request.method = "GET"
        ctx.request.headers.add "origin", "https://example.com"
        ctx.request.headers.add "access-control-request-method", "GET"
        ctx.request.headers.add "access-control-request-headers", "X-FOO"

        ctx.request.attributes[Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN] = true
      end

      listener.call event, MockEventDispatcher.new

      event.response.headers["access-control-allow-origin"].should eq "https://example.com"
      event.response.headers["access-control-allow-credentials"].should eq "true"
      event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
    end

    it "that should not allow setting origin" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
      event = new_event(ART::Events::Response) do |ctx|
        ctx.request.method = "GET"
        ctx.request.headers.add "origin", "https://example.com"
        ctx.request.headers.add "access-control-request-method", "GET"
        ctx.request.headers.add "access-control-request-headers", "X-FOO"

        ctx.request.attributes[Athena::Routing::Listeners::CORS::ALLOW_SET_ORIGIN] = false
      end

      listener.call event, MockEventDispatcher.new

      event.response.headers.should be_empty
    end

    it "without a configuration defined" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new nil
      event = new_event(ART::Events::Response)

      listener.call event, MockEventDispatcher.new

      event.response.headers.should be_empty
    end
  end
end
