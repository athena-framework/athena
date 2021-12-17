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

class TestController < ATH::Controller
  get "test" do
    "TEST"
  end
end

class MockSerializer
  include ASR::SerializerInterface

  setter data : String? = "SERIALIZED_DATA"
  setter context_assertion : Proc(ASR::SerializationContext, Nil)?

  def initialize(@context_assertion : Proc(ASR::SerializationContext, Nil)? = nil); end

  def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String
    String.build do |str|
      serialize data, format, str, context, **named_args
    end
  end

  def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
    @data.to_json io

    @context_assertion.try &.call context
  end

  def deserialize(type : ASR::Model.class, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
  end
end

class DeserializableMockSerializer(T) < MockSerializer
  setter deserialized_response : T? = nil

  def deserialize(type : ASR::Model.class, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
    @deserialized_response
  end
end

macro create_action(return_type = String, param_converters = nil, &)
  ATH::Action.new(
    ->{ ->{ {{yield}} } },
    "fake_method",
    "GET",
    "/test",
    Hash(String, Regex).new,
    Array(ATH::Arguments::ArgumentMetadata(Nil)).new,
    {{param_converters ? param_converters : "Tuple.new".id}},
    ACF::AnnotationConfigurations.new,
    Array(ATH::Params::ParamInterface).new,
    TestController,
    {{return_type}},
    typeof(Tuple.new),
  )
end

def new_context(*, request : ATH::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  HTTP::Server::Context.new request, response
end

def new_argument(has_default : Bool = false, is_nilable : Bool = false, default : Int32? = nil) : ATH::Arguments::ArgumentMetadata
  ATH::Arguments::ArgumentMetadata(Int32).new("id", has_default, is_nilable, default)
end

def new_action(
  *,
  name : String = "test",
  path : String = "/test",
  method : String = "GET",
  constraints : Hash(String, Regex) = Hash(String, Regex).new,
  arguments : Array(ATH::Arguments::ArgumentMetadata)? = nil,
  params : Array(ATH::Params::ParamInterface) = Array(ATH::Params::ParamInterface).new,
  annotation_configurations = nil
) : ATH::ActionBase
  ATH::Action.new(
    ->{ test_controller = TestController.new; ->test_controller.get_test },
    name,
    method,
    path,
    constraints,
    arguments || Array(ATH::Arguments::ArgumentMetadata(Nil)).new,
    Tuple.new,
    annotation_configurations || ACF::AnnotationConfigurations.new,
    params,
    TestController,
    String,
    typeof(Tuple.new),
  )
end

def new_request(*, path : String = "/test", method : String = "GET", action : ATH::ActionBase = new_action, body : String | IO | Nil = nil) : ATH::Request
  request = ATH::Request.new method, path, body: body
  request.action = action
  request
end

def new_request_event
  new_request_event { }
end

def new_request_event(& : ATH::Request -> _)
  request = new_request
  yield request
  ATH::Events::Request.new request
end

def new_response(*, io : IO = IO::Memory.new) : HTTP::Server::Response
  HTTP::Server::Response.new io
end
