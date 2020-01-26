require "./spec_helper"

private struct MockArgumentResolver
  include Athena::Routing::ArgumentResolverInterface

  def initialize(@exception : ::Exception? = nil); end

  def resolve(ctx : HTTP::Server::Context) : Array
    if ex = @exception
      raise ex
    end

    [] of String
  end
end

describe Athena::Routing::RouteHandler do
  describe "#handle - request" do
    describe :full do
      it "should emit the proper events and set the proper response" do
        dispatcher = TracableEventDispatcher.new
        handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new
        io = IO::Memory.new

        context = new_context response: new_response io: io

        handler.handle context

        dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Response, ART::Events::Terminate]
        context.response.headers["content-type"].should eq "application/json"
        context.response.closed?.should be_true
        context.response.status.should eq HTTP::Status::OK

        io.rewind.gets_to_end.should contain %("TEST")
      end
    end

    describe :early do
      it "should emit the proper events and set the proper response" do
        listener = AED.create_listener(ART::Events::Request) do
          event.response.status = HTTP::Status::IM_A_TEAPOT
          event.response.headers["FOO"] = "BAR"

          event.finish_request
        end

        dispatcher = TracableEventDispatcher.new
        dispatcher.add_listener ART::Events::Request, listener

        handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new
        io = IO::Memory.new

        context = new_context response: new_response io: io

        handler.handle context

        dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Response, ART::Events::Terminate]
        context.response.headers["content-type"].should eq "application/json"
        context.response.headers["FOO"].should eq "BAR"
        context.response.closed?.should be_true
        context.response.status.should eq HTTP::Status::IM_A_TEAPOT

        io.rewind.gets_to_end.should end_with "\r\n\r\n"
      end
    end
  end

  describe "#handle - exception" do
    describe ART::Exceptions::HTTPException do
      it "should emit the proper events and set correct response" do
        dispatcher = TracableEventDispatcher.new
        handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new ART::Exceptions::BadRequest.new "TEST_EX"
        io = IO::Memory.new

        context = new_context response: new_response io: io

        handler.handle context

        dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Exception, ART::Events::Response, ART::Events::Terminate]
        context.response.headers["content-type"].should eq "application/json"
        context.response.closed?.should be_true
        context.response.status.should eq HTTP::Status::BAD_REQUEST

        io.rewind.gets_to_end.should contain %({"code":400,"message":"TEST_EX"})
      end
    end

    describe ::Exception do
      it "should emit the proper events and set correct response" do
        dispatcher = TracableEventDispatcher.new
        handler = ART::RouteHandler.new dispatcher, ART::RequestStore.new, MockArgumentResolver.new Exception.new "ERR"
        io = IO::Memory.new

        context = new_context response: new_response io: io

        handler.handle context

        dispatcher.emitted_events.should eq [ART::Events::Request, ART::Events::Exception, ART::Events::Response, ART::Events::Terminate]
        context.response.headers["content-type"].should eq "application/json"
        context.response.closed?.should be_true
        context.response.status.should eq HTTP::Status::INTERNAL_SERVER_ERROR

        io.rewind.gets_to_end.should contain %({"code":500,"message":"Internal server error"})
      end
    end
  end
end
