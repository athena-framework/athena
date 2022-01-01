# :nodoc:
#
# Loads and caches a `ART::RouteCollection` from `ART::Controllers` as well as a mapping of route names to `ATH::Action`s.
module Athena::Framework::Routing::AnnotationRouteLoader
  protected class_getter routes = Hash(String, ATH::ActionBase).new

  class_getter route_collection : ART::RouteCollection do
    collection = ART::RouteCollection.new
    collection.add "foo", ART::Route.new "/foo", methods: "GET"
    collection
  end
end
