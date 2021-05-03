require "../spec_helper"

@[ADI::Register(public: true)]
class RoutingController < ART::Controller
  def initialize(@request_store : ART::RequestStore); end

  @[ARTA::Get("get/safe")]
  def safe_request_check : String
    initial_query = @request_store.request.try &.query
    sleep 2 if initial_query == "foo"
    check_query = @request_store.request.try &.query

    initial_query == check_query ? "safe" : "unsafe"
  end

  get "/container/id", return_type: UInt64 do
    ADI.container.object_id
  end

  @[ARTA::Head("/head")]
  def head : String
    "HEAD"
  end

  get "/cookies", return_type: ART::Response do
    response = ART::Response.new "FOO"
    response.headers << HTTP::Cookie.new "key", "value"
    response
  end

  @[ARTA::Get("art/response")]
  def response : ART::Response
    ART::Response.new "FOO", 418, HTTP::Headers{"content-type" => "BAR"}
  end

  @[ARTA::Get("art/streamed-response")]
  def streamed_response : ART::Response
    ART::StreamedResponse.new 418, HTTP::Headers{"content-type" => "BAR"} do |io|
      "FOO".to_json io
    end
  end

  @[ARTA::Get("art/redirect")]
  def redirect : ART::RedirectResponse
    ART::RedirectResponse.new "https://crystal-lang.org"
  end

  @[ARTA::Get("url")]
  def generate_url : String
    self.generate_url "routing_controller_response"
  end

  @[ARTA::Get("url-hash")]
  def generate_url_hash : String
    self.generate_url "routing_controller_response", {"id" => 10}
  end

  @[ARTA::Get("url-nt")]
  def generate_url_nt : String
    self.generate_url "routing_controller_response", id: 10
  end

  @[ARTA::Get("url-nt-abso")]
  def generate_url_nt_absolute : String
    self.generate_url "routing_controller_response", id: 10, reference_type: :absolute_url
  end

  @[ARTA::Get("redirect-url")]
  def redirect_url : ART::RedirectResponse
    self.redirect_to_route "routing_controller_response"
  end

  @[ARTA::Get("redirect-url-status")]
  def redirect_url_status : ART::RedirectResponse
    self.redirect_to_route "routing_controller_response", :permanent_redirect
  end

  @[ARTA::Get("redirect-url-hash")]
  def redirect_url_hash : ART::RedirectResponse
    self.redirect_to_route "routing_controller_response", {"id" => 10}
  end

  @[ARTA::Get("redirect-url-nt")]
  def redirect_url_nt : ART::RedirectResponse
    self.redirect_to_route "routing_controller_response", id: 10
  end

  @[ARTA::Get("events")]
  @[ARTA::ParamConverter("since", converter: ART::TimeConverter)]
  @[ARTA::QueryParam("since")]
  def events(since : Time? = nil) : Nil
    if s = since
      s.should be_a Time
    else
      s.should be_nil
    end
  end

  @[ARTA::Route("/custom-method", method: "FOO")]
  def custom_http_method : String
    "FOO"
  end

  @[ARTA::Get("custom-status")]
  @[ARTA::View(status: :accepted)]
  def custom_status : String
    "foo"
  end

  get "/macro/get-nil", return_type: Nil do
  end

  get "/macro/add/:num1/:num2", num1 : Int32, num2 : Int32, return_type: Int32 do
    num1 + num2
  end

  get "/macro" { "GET" }

  get "/macro/:foo", foo : String, constraints: {"foo" => /foo/} do
    foo
  end

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

  head "/macro" do
    "HEAD"
  end
end
