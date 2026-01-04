require "./spec_helper"

private struct MockArgumentResolver
  include Athena::HTTPKernel::Controller::ArgumentResolverInterface

  def initialize(@exception : ::Exception? = nil); end

  def get_arguments(request : AHTTP::Request, action : AHK::ActionBase) : Array
    if ex = @exception
      raise ex
    end

    [] of String
  end
end

private struct MockActionResolver
  include Athena::HTTPKernel::ActionResolverInterface

  def initialize(@action : AHK::ActionBase? = nil); end

  def resolve(request : AHTTP::Request) : AHK::ActionBase?
    @action
  end
end

describe Athena::HTTPKernel::HTTPKernel do
  describe "#handle" do
    describe "request" do
      describe AHTTP::Response do
        it "should use the returned response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          action = create_action(AHTTP::Response) do
            AHTTP::Response.new "TEST"
          end
          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new action

          response = handler.handle new_request(action: action)

          response.status.should eq ::HTTP::Status::OK
          response.content.should eq "TEST"

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::Response]
        end

        it "should raise if the action is unable to be resolved" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new

          expect_raises AHK::Exception::NotFound, "Unable to find the action for path '/test'." do
            handler.handle new_request
          end
        end
      end

      describe "view layer" do
        it "should resolve the returned value into a response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.listener AHK::Events::View do |event|
            event.response = AHTTP::Response.new "TEST".to_json, 201, ::HTTP::Headers{"content-type" => "application/json"}
          end

          action = new_action

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new action

          response = handler.handle request = new_request action: action

          request.attributes.get("_action").should eq action

          response.status.should eq ::HTTP::Status::CREATED
          response.content.should eq %("TEST")
          response.headers["content-type"].should eq "application/json"

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::View, AHK::Events::Response]
        end

        it "should raise an exception if the value was not handled" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          action = create_action(String?) do
            nil
          end

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new action

          expect_raises Exception, "'TestController#test' must return an `AHTTP::Response` but it returned ''." do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::View, AHK::Events::Exception]
        end
      end

      describe "that was handled via a request listener" do
        it "should emit the proper events and set the proper response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.listener AHK::Events::Request do |event|
            event.response = AHTTP::Response.new "", ::HTTP::Status::IM_A_TEAPOT, ::HTTP::Headers{"FOO" => "BAR"}
          end

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new

          response = handler.handle new_request

          response.status.should eq ::HTTP::Status::IM_A_TEAPOT
          response.content.should be_empty
          response.headers["FOO"].should eq "BAR"

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Response]
        end
      end
    end

    describe "exception" do
      describe "that is handled" do
        it "should emit the proper events and set correct response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.listener AHK::Events::Exception do |event|
            event.response = AHTTP::Response.new "HANDLED", ::HTTP::Status::BAD_REQUEST
          end

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new(AHK::Exception::BadRequest.new("TEST_EX")), MockActionResolver.new new_action

          response = handler.handle new_request

          response.status.should eq ::HTTP::Status::BAD_REQUEST
          response.content.should eq "HANDLED"

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::Exception, AHK::Events::Response]
        end
      end

      describe "that is not_handled" do
        it "should emit the proper events and set correct response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new(AHK::Exception::BadRequest.new("TEST_EX")), MockActionResolver.new new_action

          expect_raises AHK::Exception::BadRequest, "TEST_EX" do
            handler.handle new_request
          end

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::Exception]
        end
      end

      describe "when another exception is raised in the response listener" do
        it "should return the previous response" do
          dispatcher = AED::Spec::TracableEventDispatcher.new
          dispatcher.listener AHK::Events::Response do
            raise AHK::Exception::NotFound.new "NOT_FOUND"
          end

          dispatcher.listener AHK::Events::Exception do |event|
            event.response = AHTTP::Response.new "HANDLED", ::HTTP::Status::NOT_FOUND
          end

          action = create_action(AHTTP::Response) do
            AHTTP::Response.new "TEST"
          end

          handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new action

          response = handler.handle new_request action: action

          response.status.should eq ::HTTP::Status::NOT_FOUND
          response.content.should eq %(HANDLED)

          dispatcher.emitted_events.should eq [AHK::Events::Request, AHK::Events::Action, AHK::Events::Response, AHK::Events::Exception, AHK::Events::Response]
        end
      end
    end
  end

  describe "#terminate" do
    it "emits the terminate event" do
      dispatcher = AED::Spec::TracableEventDispatcher.new
      handler = AHK::HTTPKernel.new dispatcher, AHTTP::RequestStore.new, MockArgumentResolver.new, MockActionResolver.new

      handler.terminate new_request, AHTTP::Response.new

      dispatcher.emitted_events.should eq [AHK::Events::Terminate]
    end
  end
end
