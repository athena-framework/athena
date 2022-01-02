require "./spec_helper"

private struct MockArgumentResolver
  include Athena::Framework::Arguments::ArgumentResolverInterface

  def initialize(@exception : ::Exception? = nil); end

  def get_arguments(request : ATH::Request, action : ATH::ActionBase) : Array
    if ex = @exception
      raise ex
    end

    [] of String
  end
end

private struct MockControllerResolver
  include Athena::Framework::ControllerResolverInterface

  def initialize(@action : ATH::ActionBase? = nil); end

  def resolve(request : ATH::Request) : ATH::ActionBase
    @action.not_nil!
  end
end

describe Athena::Framework::RouteHandler do
  describe "#handle" do
    describe "request" do
      describe ATH::Response do
        it "should use the returned response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          action = create_action(ATH::Response) do
            ATH::Response.new "TEST"
          end
          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new action

          response = handler.handle new_request(action: action)

          response.status.should eq HTTP::Status::OK
          response.content.should eq "TEST"

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::Response]
        end
      end

      describe "view layer" do
        it "should resolve the returned value into a response" do
          listener = AED.create_listener(ATH::Events::View) do
            event.response = ATH::Response.new "TEST".to_json, 201, HTTP::Headers{"content-type" => "application/json"}
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ATH::Events::View, listener

          action = new_action

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new action

          response = handler.handle request = new_request action: action

          request.action.should eq action

          response.status.should eq HTTP::Status::CREATED
          response.content.should eq %("TEST")
          response.headers["content-type"].should eq "application/json"

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::View, ATH::Events::Response]
        end

        it "should raise an exception if the value was not handled" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          action = create_action(String?) do
            nil
          end

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new action

          expect_raises Exception, "'TestController#test' must return an `ATH::Response` but it returned ''." do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::View, ATH::Events::Exception]
        end
      end

      describe "that was handled via a request listener" do
        it "should emit the proper events and set the proper response" do
          listener = AED.create_listener(ATH::Events::Request) do
            event.response = ATH::Response.new "", HTTP::Status::IM_A_TEAPOT, HTTP::Headers{"FOO" => "BAR"}
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ATH::Events::Request, listener

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new

          response = handler.handle new_request

          response.status.should eq HTTP::Status::IM_A_TEAPOT
          response.content.should be_empty
          response.headers["FOO"].should eq "BAR"

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Response]
        end
      end
    end

    describe "exception" do
      describe "that is handled" do
        it "should emit the proper events and set correct response" do
          listener = AED.create_listener(ATH::Events::Exception) do
            event.response = ATH::Response.new "HANDLED", HTTP::Status::BAD_REQUEST
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ATH::Events::Exception, listener

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new(ATH::Exceptions::BadRequest.new("TEST_EX")), MockControllerResolver.new new_action

          response = handler.handle new_request

          response.status.should eq HTTP::Status::BAD_REQUEST
          response.content.should eq "HANDLED"

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::Exception, ATH::Events::Response]
        end
      end

      describe "that is not_handled" do
        it "should emit the proper events and set correct response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new(ATH::Exceptions::BadRequest.new("TEST_EX")), MockControllerResolver.new new_action

          expect_raises ATH::Exceptions::BadRequest, "TEST_EX" do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::Exception]
        end
      end

      describe "when another exception is raised in the response listener" do
        it "should return the previous response" do
          listener = AED.create_listener(ATH::Events::Response) do
            raise ATH::Exceptions::NotFound.new "NOT_FOUND"
          end

          ex_listener = AED.create_listener(ATH::Events::Exception) do
            event.response = ATH::Response.new "HANDLED", HTTP::Status::NOT_FOUND
          end

          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.add_listener ATH::Events::Response, listener
          dispatcher.add_listener ATH::Events::Exception, ex_listener

          action = create_action(ATH::Response) do
            ATH::Response.new "TEST"
          end

          handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new action

          response = handler.handle new_request action: action

          response.status.should eq HTTP::Status::NOT_FOUND
          response.content.should eq %(HANDLED)

          dispatcher.emitted_events.should eq [ATH::Events::Request, ATH::Events::Action, ATH::Events::Response, ATH::Events::Exception, ATH::Events::Response]
        end
      end
    end
  end

  describe "#terminate" do
    it "emits the terminate event" do
      dispatcher = AED::Spec::TracableEventDispatcher.new
      handler = ATH::RouteHandler.new dispatcher, ATH::RequestStore.new, MockArgumentResolver.new, MockControllerResolver.new

      handler.terminate new_request, ATH::Response.new

      dispatcher.emitted_events.should eq [ATH::Events::Terminate]
    end
  end
end
