require "./ext/*"

require "http/request"

require "./annotations"
require "./compiled_route"
require "./request_context"
require "./request_context_aware_interface"
require "./route"
require "./routing_handler"
require "./route_collection"
require "./route_compiler"
require "./route_provider"
require "./router"

require "./exception/*"
require "./generator/*"
require "./matcher/*"
require "./requirement/*"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Convenience alias to make referencing `ART::Annotations` types easier.
alias ARTA = ART::Annotations

# Athena's Routing component, `ART` for short, allows mapping HTTP requests to particular `ART::Route`s.
# This component is primarily intended to be used as a basis for a routing implementation for a framework, handling the majority of the heavy lifting.
#
# The routing component supports various ways to control which routes are matched, including:
#
# * Regex patterns
# * [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header values
# * HTTP method/scheme
# * Request format/locale
# * Dynamic callbacks
#
# Using the routing component involves adding `ART::Route` instances to an `ART::RouteCollection`.
# The collection is then compiled via `ART.compile`.
# An `ART::Matcher::URLMatcherInterface` or `ART::Matcher::RequestMatcherInterface` could then be used to determine which route matches a given path or `ART::Request`.
# For example:
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
#
# It is also possible to go the other way, generate a URL based on its name and set of parameters:
#
# ```
# # Generating routes based on route name and parameters is also possible.
# generator = ART::Generator::URLGenerator.new context
# generator.generate "blog_show", slug: "bar-baz", source: "Crystal" # => "/blog/bar-baz?source=Crystal"
# ```
#
# See the related types for more detailed information.
#
# ### Simple Webapp
#
# The Routing component also provides `ART::RoutingHandler` which can be used to add basic routing functionality to a [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html).
# This can be a good choice for super simple web applications that do not need any additional frameworky features.
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/architecture/routing) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-routing:
#     github: athena-framework/routing
#     version: ~> 0.1.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-routing"`.
#
# From here you would want to create an `ART::RouteCollection`, register routes with it, [compile][Athena::Routing.compile(routes)] it.
# Then an `ART::Matcher::URLMatcherInterface` or `ART::Matcher::RequestMatcherInterface` could then be used to determine which route matches a given path or `ART::Request`.
#
# TIP: Consider using the annotations provided by the component within `ART::Annotations` to handle route registration.
module Athena::Routing
  VERSION = "0.1.5"

  {% if @top_level.has_constant?("Athena") && Athena.has_constant?("Framework") && Athena::Framework.has_constant?("Request") %}
    # Represents the type of the *request* parameter within an `ART::Route::Condition`.
    #
    # Will be an `ATH::Request` instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
    alias Request = Athena::Framework::Request
  {% else %}
    # Represents the type of the *request* parameter within an `ART::Route::Condition`.
    #
    # Will be an `ATH::Request` instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
    alias Request = HTTP::Request
  {% end %}

  # Includes types related to generating URLs.
  module Generator; end

  # Includes types related to matching a path/request to a route.
  module Matcher; end

  # Both acts as a namespace for exceptions related to the `Athena::Routing` component, as well as a way to check for exceptions from the component.
  module Exception; end

  # Before `ART::Route`s can be matched or generated, they must first be compiled.
  # This process compiles each route into its `ART::CompiledRoute` representation,
  # then merges them all together into a more efficient cacheable format.
  #
  # The specifics of this process should be seen as an implementation detail.
  # All you need to worry about is calling this method with your `ART::RouteCollection`.
  def self.compile(routes : ART::RouteCollection) : Nil
    ART::RouteProvider.compile routes
  end
end
