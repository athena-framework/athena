require "./router_interface"

@[ADI::Register(name: "router", public: true)]
# Default implementation of `ART::RouterInterface`.
class Athena::Routing::Router
  include Athena::Routing::RouterInterface

  @request_store : ART::RequestStore

  protected getter generator : ART::URLGenerator { ART::URLGenerator.new self.route_collection, @request_store.request }
  protected class_getter route_collection : ART::RouteCollection { ART::RouteCollection.new }
  protected class_getter matcher : Amber::Router::RouteSet(ART::ActionBase) do
    matcher = Amber::Router::RouteSet(ART::ActionBase).new

    self.route_collection.each do |_name, route|
      matcher.add route.path, route, route.constraints
    end

    matcher
  end

  def initialize(@request_store : ART::RequestStore); end

  # :inherit:
  def generate(route : String, params : Hash(String, _)? = nil, reference_type : ART::URLGeneratorInterface::ReferenceType = :absolute_path) : String
    self.generator.generate route, params, reference_type
  end

  # :inherit:
  #
  # OPTIMIZE: Possibly raise a non `ART::Exceptions::HTTPException` here to allow caller to determine what to do.
  def match(request : HTTP::Request) : Amber::Router::RoutedResult(Athena::Routing::ActionBase)
    # Get the routes that match the given path
    matching_routes = self.class.matcher.find_routes request.path

    # Raise a 404 if it's empty
    raise ART::Exceptions::NotFound.new "No route found for '#{request.method} #{request.path}'" if matching_routes.empty?

    supported_methods = [] of String

    # Iterate over each of the matched routes
    route = matching_routes.find do |r|
      action = r.payload.not_nil!

      # Create an array of supported methods for the given action
      # This'll be used if none of the routes support the request's method
      # to show the supported methods in the error messaging
      supported_methods << action.method

      # Look for an action that supports the request's method
      action.method == request.method
    end

    # Return the matched route, or raise a 405 if none of them handle the request's method
    route || raise ART::Exceptions::MethodNotAllowed.new "No route found for '#{request.method} #{request.path}': (Allow: #{supported_methods.join(", ")})"
  end

  # :inherit:
  def route_collection : ART::RouteCollection
    self.class.route_collection
  end
end
