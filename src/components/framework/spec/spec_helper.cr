require "spec"
require "log/spec"

require "../src/athena"
require "./controllers/*"

require "athena-spec"
require "athena-event_dispatcher/spec"
require "athena-console/spec"
require "athena-validator/spec"
require "../src/spec"

Spec.before_each do
  ART.compile ATH::Routing::AnnotationRouteLoader.route_collection
end

# FIXME: Refactor these specs to not depend on calling a protected method.
include Athena::Routing

Spec.after_each do
  ART::RouteProvider.reset
end

ASPEC.run_all

# TODO: Is there a better way to handle customizing the scheme of a request w/o monkey patching it?
class ATH::Request
  property scheme : String = "http"
end

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

macro create_action(return_type = String, &)
  ATH::Action.new(
    Proc(typeof(Tuple.new), {{return_type}}).new { {{yield}} },
    Tuple.new,
    ADI::AnnotationConfigurations.new,
    TestController,
    {{return_type}},
  )
end

def new_context(*, request : ATH::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  HTTP::Server::Context.new request, response
end

def new_parameter : ATH::Controller::ParameterMetadata
  ATH::Controller::ParameterMetadata(Int32).new "id"
end

def new_action(
  *,
  arguments : Tuple = Tuple.new,
  annotation_configurations = nil,
) : ATH::ActionBase
  ATH::Action.new(
    Proc(typeof(Tuple.new), String).new { test_controller = TestController.new; test_controller.get_test },
    arguments,
    annotation_configurations || ADI::AnnotationConfigurations.new,
    TestController,
    String,
  )
end

def new_request(
  *,
  path : String = "/test",
  method : String = "GET",
  action : ATH::ActionBase = new_action,
  body : String | IO | Nil = nil,
  query : String? = nil,
  format : String = "json",
) : ATH::Request
  request = ATH::Request.new method, path, body: body
  request.attributes.set "_controller", "TestController#test", String
  request.attributes.set "_route", "test_controller_test", String
  request.action = action
  request.query = query
  request.headers = HTTP::Headers{
    "content-type" => ATH::Request::FORMATS[format].first,
  }
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

def new_response(
  *,
  io : IO = IO::Memory.new,
  status : HTTP::Status = :ok,
  headers : HTTP::Headers = HTTP::Headers.new,
) : HTTP::Server::Response
  HTTP::Server::Response.new(io).tap do |resp|
    headers.each do |k, v|
      resp.headers[k] = v
    end

    resp.status = status
  end
end
