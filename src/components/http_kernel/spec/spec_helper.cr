require "spec"
require "log/spec"
require "athena-spec"
require "../src/athena-http_kernel"
require "athena-event_dispatcher/spec"

ASPEC.run_all

class TestController
  def get_test : String
    "TEST"
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
