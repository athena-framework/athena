require "../spec_helper"

@[ADI::Register]
class RoutingController < ATH::Controller
  def initialize(@request_store : ATH::RequestStore); end

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

  get "/cookies", return_type: ATH::Response do
    response = ATH::Response.new "FOO"
    response.headers << HTTP::Cookie.new "key", "value"
    response
  end

  @[ARTA::Get("art/response")]
  def response : ATH::Response
    ATH::Response.new "FOO", 418, HTTP::Headers{"content-type" => "BAR"}
  end

  @[ARTA::Get("art/streamed-response")]
  def streamed_response : ATH::Response
    ATH::StreamedResponse.new 418, HTTP::Headers{"content-type" => "BAR"} do |io|
      "FOO".to_json io
    end
  end

  @[ARTA::Get("art/redirect")]
  def redirect : ATH::RedirectResponse
    ATH::RedirectResponse.new "https://crystal-lang.org"
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
  def redirect_url : ATH::RedirectResponse
    self.redirect_to_route "routing_controller_response"
  end

  @[ARTA::Get("redirect-url-status")]
  def redirect_url_status : ATH::RedirectResponse
    self.redirect_to_route "routing_controller_response", :permanent_redirect
  end

  @[ARTA::Get("redirect-url-hash")]
  def redirect_url_hash : ATH::RedirectResponse
    self.redirect_to_route "routing_controller_response", {"id" => 10}
  end

  @[ARTA::Get("redirect-url-nt")]
  def redirect_url_nt : ATH::RedirectResponse
    self.redirect_to_route "routing_controller_response", id: 10
  end

  @[ARTA::Get("default")]
  def default(id : Int32 = 10) : Int32
    id
  end

  @[ARTA::Get("nilable")]
  def nilable(id : Int32?) : Int32?
    id
  end

  @[ARTA::Route("/custom-method", methods: "FOO")]
  def custom_http_method : String
    "FOO"
  end

  @[ATHA::View(status: :accepted)]
  @[ARTA::Get("custom-status")]
  def custom_status : String
    "foo"
  end

  @[ARTA::Post("/echo")]
  def post_echo(request : ATH::Request) : String
    (request.body.should_not be_nil).gets_to_end
  end

  @[ARTA::Put("/echo")]
  def put_echo(request : ATH::Request) : String
    (request.body.should_not be_nil).gets_to_end
  end

  get "/macro/get-nil", return_type: Nil do
  end

  get "/macro/add/{num1}/{num2}", num1 : Int32, num2 : Int32, return_type: Int32 do
    num1 + num2
  end

  get "/macro" { "GET" }

  get "/macro/{foo<foo>}", foo : String do
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
