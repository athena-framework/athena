require "athena-spec"
require "athena-dependency_injection/spec"

# :nodoc:
#
# Monkey patch HTTP::Server::Response to allow accessing the response body directly.
class HTTP::Server::Response
  @body_io : IO = IO::Memory.new
  @body : String? = nil

  def write(slice : Bytes) : Nil
    @body_io.write slice

    previous_def
  end

  def body : String
    @body ||= @body_io.to_s
  end
end

# A set of testing utilities/types to aid in testing `Athena::Framework` related types.
#
# ### Getting Started
#
# Require this module in your `spec_helper.cr` file.
#
# ```
# # This also requires "spec" and "athena-spec".
# require "athena/spec"
# ```
#
# Add `Athena::Spec` as a development dependency, then run a `shards install`.
# See the individual types for more information.
module Athena::Framework::Spec
  # Simulates a browser to make requests to some destination.
  #
  # NOTE: Currently just acts as a client to make `HTTP` requests. This type exists to allow for introduction of other functionality in the future.
  abstract struct AbstractBrowser
    # :nodoc:
    #
    # Makes a *request* and returns the response.
    abstract def do_request(request : ATH::Request) : HTTP::Server::Response

    # Makes an HTTP request with the provided *method*, at the provided *path*, with the provided *body* and/or *headers* and returns the resulting response.
    def request(
      method : String,
      path : String,
      headers : HTTP::Headers,
      body : String | Bytes | IO | Nil
    ) : HTTP::Server::Response
      # At the moment this just calls into `do_request`.
      # Kept this as way allow for future expansion.

      self.request ATH::Request.new method, path, headers, body
    end

    # Makes an HTTP request with the provided *request*, returning the resulting response.
    def request(request : ATH::Request | HTTP::Request) : HTTP::Server::Response
      self.do_request ATH::Request.new request
    end
  end

  # Simulates a browser and makes a requests to `ATH::RouteHandler`.
  struct HTTPBrowser < AbstractBrowser
    # Returns a reference to an `ADI::Spec::MockableServiceContainer` to allow configuring the container before a test.
    def container : ADI::Spec::MockableServiceContainer
      ADI.container.as(ADI::Spec::MockableServiceContainer)
    end

    protected def do_request(request : ATH::Request) : HTTP::Server::Response
      response = HTTP::Server::Response.new IO::Memory.new

      handler = ADI.container.athena_route_handler
      athena_response = handler.handle request

      athena_response.send request, response

      handler.terminate request, athena_response

      response
    end
  end

  # Base `ASPEC::TestCase` for web based integration tests.
  #
  # NOTE: Currently only `API` based tests are supported. This type exists to allow for introduction of other types in the future.
  abstract struct WebTestCase < ASPEC::TestCase
    # Returns the `AbstractBrowser` instance to which requests should be made against.
    def create_client : AbstractBrowser
      HTTPBrowser.new
    end
  end

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
  # @[ADI::Register(public: true)]
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
  abstract struct APITestCase < WebTestCase
    @client : AbstractBrowser?

    def initialize
      # Ensure each test method has a unique container.
      self.init_container

      @client = self.create_client
    end

    # Returns a reference to the `AbstractBrowser` being used for the test.
    def client : AbstractBrowser
      @client.not_nil!
    end

    # Makes a `GET` request to the provided *path*, optionally with the provided *headers*.
    def get(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
      self.request "GET", path, headers: headers
    end

    # Makes a `POST` request to the provided *path*, optionally with the provided *body* and *headers*.
    def post(path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
      self.request "POST", path, body, headers
    end

    # Makes a `PUT` request to the provided *path*, optionally with the provided *body* and *headers*.
    def put(path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
      self.request "PUT", path, body, headers
    end

    # Makes a `DELETE` request to the provided *path*, optionally with the provided *headers*.
    def delete(path : String, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
      self.request "DELETE", path, headers: headers
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
end
