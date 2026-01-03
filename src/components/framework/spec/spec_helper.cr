require "spec"
require "log/spec"

require "../src/athena"
require "./controllers/*"

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
class AHTTP::Request
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

class MockAnnotationResolver < ATH::AnnotationResolver
  property action_annotations : ADI::AnnotationConfigurations
  property action_parameter_annotations : ADI::AnnotationConfigurations

  def initialize(
    @action_annotations : ADI::AnnotationConfigurations = ADI::AnnotationConfigurations.new,
    @action_parameter_annotations : ADI::AnnotationConfigurations = ADI::AnnotationConfigurations.new,
    *,
    @expected_controller : String? = nil,
    @expected_parameter_name : String? = nil,
  ); end

  def action_annotations(request : AHTTP::Request) : ADI::AnnotationConfigurations
    if expected_controller = @expected_controller
      request.attributes.get?("_controller", String).should eq expected_controller
    end

    @action_annotations
  end

  def action_parameter_annotations(request : AHTTP::Request, parameter_name : String) : ADI::AnnotationConfigurations
    if expected_controller = @expected_controller
      request.attributes.get?("_controller", String).should eq expected_controller
    end

    if expected_parameter_name = @expected_parameter_name
      parameter_name.should eq expected_parameter_name
    end

    @action_parameter_annotations
  end
end

macro create_action(return_type = String, &)
  AHK::Action.new(
    Proc(typeof(Tuple.new), {{return_type}}).new { {{yield}} },
    Tuple.new,
    {{return_type}},
  )
end

def new_parameter : AHK::Controller::ParameterMetadata
  AHK::Controller::ParameterMetadata(Int32).new "id"
end

def new_action(
  *,
  arguments : Tuple = Tuple.new,
) : AHK::ActionBase
  AHK::Action.new(
    Proc(typeof(Tuple.new), String).new { test_controller = TestController.new; test_controller.get_test },
    arguments,
    String,
  )
end

def new_request(
  *,
  path : String = "/test",
  method : String = "GET",
  action : AHK::ActionBase = new_action,
  body : String | IO | Nil = nil,
  query : String? = nil,
  format : String = "json",
  files : Hash(String, Array(AHTTP::UploadedFile)) = {} of String => Array(AHTTP::UploadedFile),
  headers : ::HTTP::Headers = ::HTTP::Headers.new,
) : AHTTP::Request
  request = AHTTP::Request.new method, path, body: body
  request.files.merge! files
  request.attributes.set "_controller", "TestController#test", String
  request.attributes.set "_route", "test_controller_test", String
  request.attributes.set "_action", action
  request.query = query
  request.headers = ::HTTP::Headers{
    "content-type" => AHTTP::Request::FORMATS[format].first,
  }.merge! headers
  request
end

def new_request_event(headers : ::HTTP::Headers = ::HTTP::Headers.new)
  new_request_event(headers) { }
end

def new_request_event(headers : ::HTTP::Headers = ::HTTP::Headers.new, & : AHTTP::Request -> _)
  request = new_request headers: headers
  yield request
  AHK::Events::Request.new request
end

def new_response(
  *,
  io : IO = IO::Memory.new,
  status : ::HTTP::Status = :ok,
  headers : ::HTTP::Headers = ::HTTP::Headers.new,
) : ::HTTP::Server::Response
  ::HTTP::Server::Response.new(io).tap do |resp|
    headers.each do |k, v|
      resp.headers[k] = v
    end

    resp.status = status
  end
end

ATH.configure({
  framework: {
    file_uploads: {
      enabled: true,
    },
  },
})
