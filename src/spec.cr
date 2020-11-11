require "athena-spec"
require "athena-dependency_injection/spec"

# :nodoc:
#
# Monkey patch HTTP::Server::Response to allow accessing the response body directly.
class HTTP::Server::Response
  @body_io : IO = IO::Memory.new
  getter body : String? = nil

  def write(slice : Bytes) : Nil
    @body_io.write slice

    previous_def
  end

  def body : String
    @body ||= @body_io.to_s
  end
end

# A set of testing utilities/types to aid in testing `Athena::Routing` related types.
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
module Athena::Routing::Spec
  # Simulates a browser to make requests to some destination.
  abstract struct AbstractBrowser
    # Makes a *request* and returns the response.
    abstract def do_request(request : HTTP::Request) : HTTP::Server::Response

    def request(
      method : String,
      path : String,
      headers : HTTP::Headers,
      body : String | Bytes | IO | Nil
    ) : HTTP::Server::Response
      # At the moment this just calls into `do_request`.
      # Kept this as way allow for future expansion.

      self.do_request HTTP::Request.new method, path, headers, body
    end
  end

  # Simulates a browser and makes a requests to `ART::RouteHandler`.
  struct HTTPBrowser < AbstractBrowser
    def container : ADI::Spec::MockableServiceContainer
      ADI.container.as(ADI::Spec::MockableServiceContainer)
    end

    protected def do_request(request : HTTP::Request) : HTTP::Server::Response
      route_handler = ADI.container.athena_routing_route_handler

      response = HTTP::Server::Response.new IO::Memory.new

      athena_response = route_handler.handle(HTTP::Server::Context.new(request, response))

      response.close

      route_handler.terminate request, athena_response

      response
    end
  end

  abstract struct WebTestCase < ASPEC::TestCase
    # Returns the `AbstractBrowser` instance to use for the tests.
    def create_client : AbstractBrowser
      HTTPBrowser.new
    end
  end

  abstract struct APITestCase < WebTestCase
    getter! client : AbstractBrowser

    def initialize
      # Ensure each test method has a unique container.
      self.init_container

      @client = self.create_client
    end

    def request(method : String, path : String, body : String | Bytes | IO | Nil = nil, headers : HTTP::Headers = HTTP::Headers.new) : HTTP::Server::Response
      self.client.request method, path, headers, body
    end

    # Helper method to init the container.
    # Creates a new container instance and assigns it to the current fiber.
    protected def init_container : Nil
      Fiber.current.container = ADI::Spec::MockableServiceContainer.new
    end
  end
end
