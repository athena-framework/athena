require "../spec_helper"

private class MockURLGenerator
  include Athena::Routing::URLGeneratorInterface

  setter expected_route, expected_reference_type, generated_url

  def initialize(
    @expected_route : String = "some_route",
    @expected_reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path,
    @generated_url : String = "URL"
  ); end

  def generate(route : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
    route.should eq @expected_route
    reference_type.should eq @expected_reference_type

    params.try &.each do |key, value|
      @generated_url = @generated_url.gsub "{{#{key}}}", value
    end

    @generated_url
  end
end

@[ASPEC::TestCase::Focus]
struct ViewHandlerTest < ASPEC::TestCase
  @url_generator : MockURLGenerator
  @serializer : MockSerializer
  @request_store : ART::RequestStore

  def initialize
    @url_generator = MockURLGenerator.new
    @serializer = MockSerializer.new
    @request_store = ART::RequestStore.new
  end

  @[DataProvider("format_provider")]
  def test_supports_format(expected : Bool, custom_format_name : String, format : String?) : Nil
    view_handler = self.create_view_handler
    view_handler.register_handler custom_format_name do
      ART::Response.new
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
             ART::View(String).new data: data, status: view_status
           else
             ART::View(Nil).new status: view_status
           end

    view_handler = if empty_content_status
                     self.create_view_handler ART::Config::ViewHandler.new empty_content_status: empty_content_status
                   else
                     self.create_view_handler
                   end

    view_handler.create_response(view, HTTP::Request.new("GET", "/"), "json").status.should eq expected_status
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
    view_handler = self.create_view_handler ART::Config::ViewHandler.new empty_content_status: HTTP::Status::USE_PROXY

    view = ART::View(String?).new nil
    view.location = "location"

    response = view_handler.create_response view, HTTP::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::USE_PROXY
    response.headers["location"].should eq "location"
  end

  def test_create_response_with_location_and_data : Nil
    view_handler = self.create_view_handler

    view = ART::View(String).new "DATA", status: HTTP::Status::CREATED
    view.location = "location"

    response = view_handler.create_response view, HTTP::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::CREATED
    response.headers["location"].should eq "location"
    response.content.should eq %("SERIALIZED_DATA")
  end

  def test_create_response_with_route : Nil
    view_handler = self.create_view_handler

    @url_generator.generated_url = "/foo/{{foo}}"
    @url_generator.expected_reference_type = ART::URLGeneratorInterface::ReferenceType::Absolute_URL

    view = ART::View(String).new "DATA", status: HTTP::Status::CREATED
    view.route = "some_route"
    view.route_params = {"foo" => "bar"}

    response = view_handler.create_response view, HTTP::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::CREATED
    response.headers["location"].should eq "/foo/bar"
  end

  def test_create_response_without_location : Nil
    view_handler = self.create_view_handler

    view = ART::View.new "DATA"

    response = view_handler.create_response view, HTTP::Request.new("GET", "/"), "json"

    response.status.should eq HTTP::Status::OK
    response.content.should eq %("SERIALIZED_DATA")
  end

  def test_serialize_nil : Nil
  end

  def test_create_response : Nil
  end

  def test_handle_custom : Nil
  end

  def test_handle_not_supported : Nil
  end

  def test_configurable_values : Nil
  end

  private def create_view_handler(config : ART::Config::ViewHandler = ART::Config::ViewHandler.new) : ART::View::ViewHandler
    ART::View::ViewHandler.new(
      config,
      @url_generator,
      @serializer,
      @request_store,
      ([] of Athena::Routing::View::FormatHandlerInterface),
    )
  end
end
