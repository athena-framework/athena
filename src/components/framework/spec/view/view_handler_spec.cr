require "../spec_helper"

private class MockURLGenerator
  include Athena::Routing::Generator::Interface

  property context : ART::RequestContext = ART::RequestContext.new

  setter expected_route, expected_reference_type, generated_url

  def initialize(
    @expected_route : String = "some_route",
    @expected_reference_type : ART::Generator::ReferenceType = :absolute_path,
    @generated_url : String = "URL"
  ); end

  def generate(route : String, params : Hash(String, String | ::Nil) = Hash(String, String | ::Nil).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String
    route.should eq @expected_route
    reference_type.should eq @expected_reference_type

    params.try &.each do |key, value|
      @generated_url = @generated_url.gsub "{{#{key}}}", value
    end

    @generated_url
  end
end

struct ViewHandlerTest < ASPEC::TestCase
  @url_generator : MockURLGenerator
  @serializer : MockSerializer
  @request_store : ATH::RequestStore

  def initialize
    @url_generator = MockURLGenerator.new
    @serializer = MockSerializer.new
    @request_store = ATH::RequestStore.new
  end

  @[DataProvider("format_provider")]
  def test_supports_format(expected : Bool, custom_format_name : String, format : String?) : Nil
    view_handler = self.create_view_handler
    view_handler.register_handler custom_format_name do
      ATH::Response.new
    end

    view_handler.supports?(format || "html").should eq expected
  end

  def format_provider : Tuple
    {
      {false, "xml", nil},
      {true, "html", nil},
      {true, "html", "json"},
    }
  end

  @[DataProvider("status_provider")]
  def test_status(expected_status : HTTP::Status, view_status : HTTP::Status?, data : String?, empty_content_status : HTTP::Status?) : Nil
    view = if data
             ATH::View(String).new data: data, status: view_status
           else
             ATH::View(Nil).new status: view_status
           end

    view_handler = if empty_content_status
                     self.create_view_handler ATH::Config::ViewHandler.new empty_content_status: empty_content_status
                   else
                     self.create_view_handler
                   end

    view_handler.create_response(view, ATH::Request.new("GET", "/"), "json").status.should eq expected_status
  end

  def status_provider : Hash
    {
      "custom view status"                 => {HTTP::Status::IM_A_TEAPOT, HTTP::Status::IM_A_TEAPOT, nil, nil},
      "non empty content"                  => {HTTP::Status::OK, nil, "DATA", nil},
      "empty content default empty status" => {HTTP::Status::NO_CONTENT, nil, nil, nil},
      "empty content custom empty status"  => {HTTP::Status::IM_A_TEAPOT, nil, nil, HTTP::Status::IM_A_TEAPOT},
    }
  end

  def test_create_response_with_location : Nil
    view_handler = self.create_view_handler ATH::Config::ViewHandler.new empty_content_status: HTTP::Status::USE_PROXY

    view = ATH::View(String?).new nil
    view.location = "location"

    response = view_handler.create_response view, ATH::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::USE_PROXY
    response.headers["location"].should eq "location"
  end

  def test_create_response_with_location_and_data : Nil
    view_handler = self.create_view_handler

    view = ATH::View(String).new "DATA", status: HTTP::Status::CREATED
    view.location = "location"

    response = view_handler.create_response view, ATH::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::CREATED
    response.headers["location"].should eq "location"
    response.content.should eq %("SERIALIZED_DATA")
  end

  def test_create_response_with_route : Nil
    view_handler = self.create_view_handler

    @url_generator.generated_url = "/foo/{{foo}}"
    @url_generator.expected_reference_type = ART::Generator::ReferenceType::ABSOLUTE_URL

    view = ATH::View(String).new "DATA", status: HTTP::Status::CREATED
    view.route = "some_route"
    view.route_params = {"foo" => "bar"} of String => String?

    response = view_handler.create_response view, ATH::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::CREATED
    response.headers["location"].should eq "/foo/bar"
  end

  def test_create_response_without_location : Nil
    view_handler = self.create_view_handler

    view = ATH::View.new "DATA"

    response = view_handler.create_response view, ATH::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::OK
    response.content.should eq %("SERIALIZED_DATA")
  end

  @[DataProvider("serialize_nil_provider")]
  def test_serialize_nil_view_handler(emit_nil : Bool) : Nil
    view_handler = self.create_view_handler ATH::Config::ViewHandler.new emit_nil: emit_nil

    @serializer.context_assertion = ->(context : ASR::SerializationContext) do
      context.emit_nil?.should eq emit_nil
    end

    view_handler.create_response ATH::View(Nil).new, ATH::Request.new("GET", "/"), "json"
  end

  def serialize_nil_provider : Tuple
    {
      {true},
      {false},
    }
  end

  def test_handle_unsupported_format : Nil
    request = ATH::Request.new "GET", "/"
    request.request_format = "rss"

    expect_raises ATH::Exceptions::NotAcceptable, "The server is unable to return a response in the requested format: 'rss'." do
      self.create_view_handler.handle ATH::View(Nil).new, request
    end
  end

  def test_handle_custom_handler : Nil
    response = ATH::Response.new

    view_handler = self.create_view_handler
    view_handler.register_handler "rss" do
      response
    end

    request = ATH::Request.new "GET", "/"
    request.request_format = "rss"

    view_handler.handle(ATH::View(Nil).new, request).should be response
  end

  def test_configurable_values : Nil
    view_handler = self.create_view_handler
    view_handler.serialization_groups = {"one", "two"}
    view_handler.serialization_version = "1.2.3"
    view_handler.serialization_version = SemanticVersion.new 4, 5, 6
    view_handler.emit_nil = true

    @serializer.context_assertion = ->(context : ASR::SerializationContext) do
      context.emit_nil?.should be_true
      context.version.should eq SemanticVersion.new 4, 5, 6
      context.groups.should eq Set{"one", "two"}
    end

    view_handler.create_response ATH::View(Nil).new, ATH::Request.new("GET", "/"), "json"
  end

  private def create_view_handler(config : ATH::Config::ViewHandler = ATH::Config::ViewHandler.new) : ATH::View::ViewHandler
    ATH::View::ViewHandler.new(
      config,
      @url_generator,
      @serializer,
      @request_store,
      ([] of Athena::Framework::View::FormatHandlerInterface),
    )
  end
end
