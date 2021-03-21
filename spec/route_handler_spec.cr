require "./spec_helper"

private struct MockArgumentResolver
  include Athena::Routing::Arguments::ArgumentResolverInterface

  def initialize(@exception : ::Exception? = nil); end

  def get_arguments(request : HTTP::Request, action : ART::ActionBase) : Array
    if ex = @exception
      raise ex
    end

    [] of String
  end
end

describe Athena::Routing::RouteHandler do
  describe "#handle" do
    describe "request" do
      describe ART::Response do
        it "should use the returned response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new
          action = create_action(ART::Response) do
            ART::Response.new "TEST"
          end

          response = handler.handle new_request(action: action)

          response.status.should eq HTTP::Status::OK
          response.content.should eq "TEST"

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::Response]
        end
      end

      describe "view layer" do
        it "should use the resolve the returned value into a response" do
          listener = AED.create_listener(ART::Events::View) do
            event.response = ART::Response.new "TEST".to_json, 201, HTTP::Headers{"content-type" => "application/json"}
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ART::Events::View, listener

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new

          response = handler.handle new_request

          response.status.should eq HTTP::Status::CREATED
          response.content.should eq %("TEST")
          response.headers.should eq HTTP::Headers{"content-type" => "application/json"}

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::View, ART::Events::Response]
        end

        it "should raise an exception if the value was not handled" do
          dispatcher = AED::Spec::TracableEventDispatcher.new

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new

          expect_raises Exception, "TestController#test must return an `ART::Response` but it returned ''." do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::View, ART::Events::Exception]
        end
      end

      describe "that was handled via a request listener" do
        it "should emit the proper events and set the proper response" do
          listener = AED.create_listener(ART::Events::Request) do
            event.response = ART::Response.new "", HTTP::Status::IM_A_TEAPOT, HTTP::Headers{"FOO" => "BAR"}
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ART::Events::Request, listener

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new

          response = handler.handle new_request

          response.status.should eq HTTP::Status::IM_A_TEAPOT
          response.content.should be_empty
          response.headers.should eq HTTP::Headers{"FOO" => "BAR"}

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Response]
        end
      end
    end

    describe "exception" do
      describe "that is handled" do
        it "should emit the proper events and set correct response" do
          listener = AED.create_listener(ART::Events::Exception) do
            event.response = ART::Response.new "HANDLED", HTTP::Status::BAD_REQUEST
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ART::Events::Exception, listener

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new ART::Exceptions::BadRequest.new "TEST_EX"

          response = handler.handle new_request

          response.status.should eq HTTP::Status::BAD_REQUEST
          response.content.should eq "HANDLED"

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::Exception, ART::Events::Response]
        end
      end

      describe "that is not_handled" do
        it "should emit the proper events and set correct response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new ART::Exceptions::BadRequest.new "TEST_EX"

          expect_raises ART::Exceptions::BadRequest, "TEST_EX" do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::Exception]
        end
      end

      describe "when another exception is raised in the response listener" do
        it "should return the previous response" do
          listener = AED.create_listener(ART::Events::Response) do
            raise ART::Exceptions::NotFound.new "NOT_FOUND"
          end

          ex_listener = AED.create_listener(ART::Events::Exception) do
            event.response = ART::Response.new "HANDLED", HTTP::Status::NOT_FOUND
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ART::Events::Response, listener
          dispatcher.add_listener ART::Events::Exception, ex_listener

          handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new

          action = create_action(ART::Response) do
            ART::Response.new "TEST"
          end

          response = handler.handle new_request action: action

          response.status.should eq HTTP::Status::NOT_FOUND
          response.content.should eq %(HANDLED)

          dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Action, ART::Events::Response, ART::Events::Exception, ART::Events::Response]
        end
      end
    end
  end

  describe "#terminate" do
    it "emits the terminate event" do
      dispatcher = AED::Spec::TracableEventDispatcher.new
      handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new

      handler.terminate new_request, ART::Response.new

      dispatcher.emitted_events.should eq [ART::Events::Terminate]
    end
  end
end
