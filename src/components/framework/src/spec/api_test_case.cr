require "./web_test_case"

# A `WebTestCase` implementation with the intent of testing API controllers.
# Can be extended to add additional application specific configuration, such as setting up an authenticated user to make the request as.
#
# ## Usage
#
# Say we want to test the following controller:
#
# ```
# class ExampleController < ATH::Controller
#   @[ATHA::QueryParam("negative")]
#   @[ARTA::Get("/add/{value1}/{value2}")]
#   def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
#     sum = value1 + value2
#     negative ? -sum : sum
#   end
# end
# ```
#
# We can define a struct inheriting from `self` to implement our test logic:
#
# ```
# struct ExampleControllerTest < ATH::Spec::APITestCase
#   def test_add_positive : Nil
#     self.get("/add/5/3").body.should eq "8"
#   end
#
#   def test_add_negative : Nil
#     self.get("/add/5/3?negative=true").body.should eq "-8"
#   end
# end
# ```
#
# The `#request` method is used to make our requests to the API, then we run are assertions against the resulting `HTTP::Server::Response`.
# A key thing to point out is that there is no `HTTP::Server` involved, thus resulting in more performant specs.
#
# TIP: Checkout the built in [expecations][Athena::Framework::Spec::Expectations::HTTP] to make testing easier.
#
# ATTENTION: Be sure to call `Athena::Spec.run_all` to your `spec_helper.cr` to ensure all test case instances are executed.
#
# ### Mocking External Dependencies
#
# The previous example was quite simple. However, most likely a controller is going to have dependencies on various other services; such as an API client to make requests to a third party API.
# By default each test will be executed with the same services as it would normally, i.e. those requests to the third party API would actually be made.
# To solve this we can create a mock implementation of the API client and make it so that implementation is injected when the test runs.
#
# ```
# # Create an example API client.
# @[ADI::Register]
# class APIClient
#   def fetch_latest_data : String
#     # Assume this method actually makes an `HTTP` request to get the latest data.
#     "DATA"
#   end
# end
#
# # Define a mock implementation of our APIClient that does not make a request and just returns mock data.
# class MockAPIClient < APIClient
#   def fetch_latest_data : String
#     # This could also be an instance variable that gets set when this mock is created.
#     "MOCK_DATA"
#   end
# end
#
# # Enable our API client to be replaced in the service container.
# class ADI::Spec::MockableServiceContainer
#   # Use the block version of the `property` macro to use our mocked client by default, while still allowing it to be replaced at runtime.
#   #
#   # The block version of `getter` could also be used if you don't need to set it at runtime.
#   # The `setter` macro could be also if you only want to allow replacing it at runtime.
#   property(api_client) { MockAPIClient.new }
# end
#
# @[ADI::Register]
# class ExampleServiceController < ATH::Controller
#   def initialize(@api_client : APIClient); end
#
#   @[ARTA::Post("/sync")]
#   def sync_data : String
#     # Use the injected api client to get the latest data to sync.
#     data = @api_client.fetch_latest_data
#
#     # ...
#
#     data
#   end
# end
#
# struct ExampleServiceControllerTest < ATH::Spec::APITestCase
#   def initialize
#     super
#
#     # Our API client could also have been replaced at runtime;
#     # such as if you wanted provide it what data it should return on a test by test basis.
#     # self.client.container.api_client = MockAPIClient.new
#   end
#
#   def test_sync_data : Nil
#     self.post("/sync").body.should eq %("MOCK_DATA")
#   end
# end
# ```
#
# TIP: See `ADI::Spec::MockableServiceContainer` for more details on mocking services.
#
# Each `test_*` method has its own service container instance.
# Any services that are mutated/replaced within the `initialize` method will affect all `test_*` methods.
# However, services can also be mutated/replaced within specific `test_*` methods to scope it that particular test;
# just be sure that you do it _before_ calling `#request`.
abstract struct Athena::Framework::Spec::APITestCase < ATH::Spec::WebTestCase
  def initialize
    # Ensure each test method has a unique container.
    self.init_container

    super
  end

  # Returns a reference to the `AbstractBrowser` being used for the test.
  def client : ATH::Spec::HTTPBrowser
    @client.as(ATH::Spec::HTTPBrowser).not_nil!
  end

  # Makes a `DELETE` request to the provided *path*, optionally with the provided *headers*.
  def delete(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "DELETE", path, headers: headers
  end

  # Makes a `GET` request to the provided *path*, optionally with the provided *headers*.
  def get(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "GET", path, headers: headers
  end

  # Makes a `HEAD` request to the provided *path*, optionally with the provided *headers*.
  def head(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "HEAD", path, headers: headers
  end

  # Makes a `LINK` request to the provided *path*, optionally with the provided *headers*.
  def link(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "LINK", path, headers: headers
  end

  # Makes a `PATCH` request to the provided *path*, optionally with the provided *body* and *headers*.
  def patch(path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "PATCH", path, headers: headers
  end

  # Makes a `POST` request to the provided *path*, optionally with the provided *body* and *headers*.
  def post(path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "POST", path, body, headers
  end

  # Makes a `PUT` request to the provided *path*, optionally with the provided *body* and *headers*.
  def put(path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "PUT", path, body, headers
  end

  # Makes a `UNLINK` request to the provided *path*, optionally with the provided *headers*.
  def unlink(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request "UNLINK", path, body, headers
  end

  # See `AbstractBrowser#request`.
  def request(method : String, path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
    self.request ATH::Request.new method, path, headers, body
  end

  # :ditto:
  def request(request : HTTP::Request | ATH::Request) : HTTP::Server::Response
    self.client.request ATH::Request.new request
  end

  # Helper method to init the container.
  # Creates a new container instance and assigns it to the current fiber.
  protected def init_container : Nil
    Fiber.current.container = ADI::Spec::MockableServiceContainer.new
  end
end
