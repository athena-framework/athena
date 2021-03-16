require "../spec_helper"

private def new_response_event
  new_response_event() { }
end

private def new_response_event(& : HTTP::Request -> _)
  request = new_request
  yield request
  ART::Events::Response.new request, ART::Response.new
end

private def assert_headers(response : ART::Response, origin : String = "https://example.com") : Nil
  response.headers["access-control-allow-credentials"].should eq "true"
  response.headers["access-control-allow-headers"].should eq "X-FOO"
  response.headers["access-control-allow-methods"].should eq "POST, GET"
  response.headers["access-control-allow-origin"].should eq origin
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

      listener.call event, AED::Spec::TracableEventDispatcher.new

      event.response.should be_nil
      event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
    end

    it "without the origin header" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_empty_config
      event = new_request_event

      listener.call event, AED::Spec::TracableEventDispatcher.new

      event.response.should be_nil
      event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
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

          listener.call event, AED::Spec::TracableEventDispatcher.new

          response = event.response.should_not be_nil
          response.headers["vary"].should eq "origin"
          response.headers["access-control-allow-methods"].should eq "GET, POST, HEAD"
          event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
        end
      end

      it "with an unsupported request method" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "LINK"
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        response = event.response.should_not be_nil
        response.status.should eq HTTP::Status::METHOD_NOT_ALLOWED
        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

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
          listener.call event, AED::Spec::TracableEventDispatcher.new
        end

        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        event.response.should be_nil
      end

      it "with an invalid origin" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://admin.example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        response = event.response.should_not be_nil
        response.headers["vary"].should eq "origin"
        response.headers["access-control-allow-methods"].should eq "POST, GET"
        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
      end

      describe "proper request" do
        it "static origin" do
          listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://example.com"
            request.headers.add "access-control-request-method", "GET"
            request.headers.add "access-control-request-headers", "X-FOO"
          end

          listener.call event, AED::Spec::TracableEventDispatcher.new

          event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

          assert_headers event.response.should_not be_nil
        end

        it "regex origin" do
          listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
          event = new_request_event do |request|
            request.method = "OPTIONS"
            request.headers.add "origin", "https://api.example.com"
            request.headers.add "access-control-request-method", "GET"
            request.headers.add "access-control-request-headers", "X-FOO"
          end

          listener.call event, AED::Spec::TracableEventDispatcher.new

          event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

          assert_headers event.response.should_not(be_nil), "https://api.example.com"
        end
      end

      it "without the access-control-request-headers header" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

        assert_headers event.response.should_not be_nil
      end

      it "without the access-control-request-headers header and wildcard in allow_headers config" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new MockCorsConfigResolver.get_config_with_wildcards
        event = new_request_event do |request|
          request.method = "OPTIONS"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false

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

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_false
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

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.request.attributes.has?(ART::Listeners::CORS::ALLOW_SET_ORIGIN).should be_true
        event.response.should be_nil
      end
    end
  end

  describe "#call - response" do
    describe "with a proper request" do
      it "static origin" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_response_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"

          request.attributes.set ART::Listeners::CORS::ALLOW_SET_ORIGIN, true
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.response.headers["access-control-allow-origin"].should eq "https://example.com"
        event.response.headers["access-control-allow-credentials"].should eq "true"
        event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
      end

      it "valid regex origin" do
        listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
        event = new_response_event do |request|
          request.method = "GET"
          request.headers.add "origin", "https://app.example.com"
          request.headers.add "access-control-request-method", "GET"
          request.headers.add "access-control-request-headers", "X-FOO"

          request.attributes.set ART::Listeners::CORS::ALLOW_SET_ORIGIN, true
        end

        listener.call event, AED::Spec::TracableEventDispatcher.new

        event.response.headers["access-control-allow-origin"].should eq "https://app.example.com"
        event.response.headers["access-control-allow-credentials"].should eq "true"
        event.response.headers["access-control-expose-headers"].should eq "HEADER1, HEADER2"
      end
    end

    it "that should not allow setting origin" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new
      event = new_response_event do |request|
        request.method = "GET"
        request.headers.add "origin", "https://example.com"
        request.headers.add "access-control-request-method", "GET"
        request.headers.add "access-control-request-headers", "X-FOO"

        request.attributes.set ART::Listeners::CORS::ALLOW_SET_ORIGIN, false
      end

      listener.call event, AED::Spec::TracableEventDispatcher.new

      event.response.headers.should be_empty
    end

    it "without a configuration defined" do
      listener = ART::Listeners::CORS.new MockCorsConfigResolver.new nil
      event = new_response_event

      listener.call event, AED::Spec::TracableEventDispatcher.new

      event.response.headers.should be_empty
    end
  end
end
