require "./request_matcher_interface"
require "./url_generator_interface"

# Interface for routing types.
#
# A router instance must include both `ART::RequestMatcherInterface` and `ART:URLGeneratorInterface
# as well as expose the routes via an `#route_collection` method.
module Athena::Routing::RouterInterface
  include Athena::Routing::RequestMatcherInterface
  include Athena::Routing::URLGeneratorInterface

  # Returns the `ART::RouteCollection` associated with this router.
  abstract def route_collection : ART::RouteCollection
end
