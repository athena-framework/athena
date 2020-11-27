require "./request_matcher_interface"
require "./url_generator_interface"

module Athena::Routing::RouterInterface
  include Athena::Routing::RequestMatcherInterface
  include Athena::Routing::URLGeneratorInterface

  abstract def route_collection : ART::RouteCollection
end
