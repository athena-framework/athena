# Allows matching a request path, or `ART::Request` in the case of `ART::Matcher::RequestMatcherInterface`, to its related route.
#
# ```
# # Create a new route collection and add a route with a single parameter to it.
# routes = ART::RouteCollection.new
# routes.add "blog_show", ART::Route.new "/blog/{slug}"
#
# # Compile the routes.
# ART.compile routes
#
# # Represents the request in an agnostic data format.
# # In practice this would be created from the current `ART::Request`.
# context = ART::RequestContext.new
#
# # Match a request by path.
# matcher = ART::Matcher::URLMatcher.new context
# matcher.match "/blog/foo-bar" # => {"_route" => "blog_show", "slug" => "foo-bar"}
# ```
module Athena::Routing::Matcher::URLMatcherInterface
  include Athena::Routing::RequestContextAwareInterface

  # Tries to match the provided *path* to its related route.
  # Returns a hash of the route's defaults and parameters resolved from the *path*.
  #
  # Raises an `ART::Exception::ResourceNotFound` if no route could be matched.
  #
  # Raises an `ART::Exception::MethodNotAllowed` if a route exists but not for the current HTTP method.
  abstract def match(path : String) : Hash(String, String?)

  # Tries to match the provided *path* to its related route.
  # Returns a hash of the route's defaults and parameters resolved from the *path*.
  #
  # Returns `nil` if no route could be matched or a route exists but not for the current HTTP method.
  abstract def match?(path : String) : Hash(String, String?)?
end
