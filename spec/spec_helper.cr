require "spec"
require "log/spec"

require "../src/athena"
require "./controllers/*"

require "athena-spec"
require "athena-event_dispatcher/spec"
require "athena-validator/spec"
require "../src/spec"

include ASPEC::Methods

ASPEC.run_all

class TestController < ART::Controller
  get "test" do
    "TEST"
  end
end

macro create_action(return_type, view_context = nil, &)
  ART::Action.new(
    ->{ ->{ {{yield}} } },
    "fake_method",
    "GET",
    "/test",
    Hash(String, Regex).new,
    Array(ART::Arguments::ArgumentMetadata(Nil)).new,
    Array(ART::ParamConverterInterface::ConfigurationInterface).new,
    {{view_context}} || ART::Action::ViewContext.new,
    ACF::AnnotationConfigurations.new,
    Array(ART::Params::ParamInterface).new,
    TestController,
    {{return_type}},
    typeof(Tuple.new),
  )
end

def new_context(*, request : HTTP::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  HTTP::Server::Context.new request, response
end

def new_argument(has_default : Bool = false, is_nilable : Bool = false, default : Int32? = nil) : ART::Arguments::ArgumentMetadata
  ART::Arguments::ArgumentMetadata(Int32).new("id", has_default, is_nilable, default)
end

def new_action(
  arguments : Array(ART::Arguments::ArgumentMetadata)? = nil,
  param_converters : Array(ART::ParamConverterInterface::ConfigurationInterface)? = nil,
  view_context : ART::Action::ViewContext = ART::Action::ViewContext.new,
  params : Array(ART::Params::ParamInterface) = Array(ART::Params::ParamInterface).new
) : ART::ActionBase
  ART::Action.new(
    ->{ test_controller = TestController.new; ->test_controller.get_test },
    "get_test",
    "GET",
    "/test",
    Hash(String, Regex).new,
    arguments || Array(ART::Arguments::ArgumentMetadata(Nil)).new,
    param_converters || Array(ART::ParamConverterInterface::ConfigurationInterface).new,
    view_context,
    ACF::AnnotationConfigurations.new,
    params,
    TestController,
    String,
    typeof(Tuple.new),
  )
end

def new_request(*, path : String = "/test", method : String = "GET", action : ART::ActionBase = new_action) : HTTP::Request
  request = HTTP::Request.new method, path
  request.action = action
  request
end

def new_response(*, io : IO = IO::Memory.new) : HTTP::Server::Response
  HTTP::Server::Response.new io
end
