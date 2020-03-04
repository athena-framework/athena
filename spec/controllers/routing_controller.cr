require "../spec_helper"

class RoutingController < ART::Controller
  include ADI::Injectable

  def initialize(@request_store : Athena::Routing::RequestStore); end

  @[ART::Get("get/safe")]
  def safe_request_check : String
    initial_query = @request_store.request.try &.query
    sleep 2 if initial_query == "foo"
    check_query = @request_store.request.try &.query

    initial_query == check_query ? "safe" : "unsafe"
  end

  @[ART::Get("art/response")]
  def response : ART::Response
    ART::Response.new "FOO", 418, HTTP::Headers{"content-type" => "BAR"}
  end

  @[ART::Get("art/redirect")]
  def redirect : ART::RedirectResponse
    ART::RedirectResponse.new "https://crystal-lang.org"
  end

  get "/macro/:foo", foo : String, constraints: {"foo" => /foo/} do
    foo
  end

  get "/macro/get-nil", return_type: Nil do
  end

  get "/macro/add/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
    num1 + num2
  end

  get "/macro" { "GET" }

  post "/macro" do
    "POST"
  end

  put "/macro" do
    "PUT"
  end

  patch "/macro" do
    "PATCH"
  end

  delete "/macro" do
    "DELETE"
  end
end
