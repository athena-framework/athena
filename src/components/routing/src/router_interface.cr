require "./matcher/url_matcher_interface"
require "./generator/interface"

module Athena::Routing::RouterInterface
  include Athena::Routing::Matcher::URLMatcherInterface
  include Athena::Routing::Generator::Interface

  abstract def route_collection : ART::RouteCollection
end
