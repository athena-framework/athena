require "../spec_helper"

@[ADI::Register(public: true)]
class RoutingController < ART::Controller
  def initialize(@request_store : ART::RequestStore); end

  @[ART::Get("get/safe")]
  def safe_request_check : String
    initial_query = @request_store.request.try &.query
    sleep 2 if initial_query == "foo"
    check_query = @request_store.request.try &.query

    initial_query == check_query ? "safe" : "unsafe"
  end

  get "/container/id", return_type: UInt64 do
    ADI.container.object_id
  end

  @[ART::Get("art/response")]
  def response : ART::Response
    ART::Response.new "FOO", 418, HTTP::Headers{"content-type" => "BAR"}
  end

  @[ART::Get("art/redirect")]
  def redirect : ART::RedirectResponse
    ART::RedirectResponse.new "https://crystal-lang.org"
  end

  @[ART::Get("events")]
  @[ART::ParamConverter("since", converter: ART::TimeConverter)]
  @[ART::QueryParam("since")]
  def events(since : Time? = nil) : Nil
    if s = since
      s.should be_a Time
    else
      s.should be_nil
    end
  end

  @[ART::Route("/custom-method", method: "FOO")]
  def custom_http_method : String
    "FOO"
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

  link "/macro" do
    "LINK"
  end

  unlink "/macro" do
    "UNLINK"
  end
end
