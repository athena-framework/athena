require "./ext/regex"

require "http/request"

require "./annotations"
require "./compiled_route"
require "./request_context"
require "./request_context_aware_interface"
require "./route"
require "./route_collection"
require "./route_compiler"
require "./route_provider"
require "./routing_handler"
require "./router"

require "./exception/*"
require "./generator/*"
require "./matcher/*"
require "./requirement/*"

# Convenience alias to make referencing `Athena::Routing` types easier.
alias ART = Athena::Routing

# Convenience alias to make referencing `ART::Annotations` types easier.
alias ARTA = ART::Annotations

# Provides a performant and robust HTTP based routing library/framework.
module Athena::Routing
  VERSION = "0.1.9"

  {% if @top_level.has_constant?("Athena") && Athena.has_constant?("Framework") && Athena::Framework.has_constant?("Request") %}
    # Represents the type of the *request* parameter within an `ART::Route::Condition`.
    #
    # Will be an [ATH::Request](/Framework/Request) instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
    alias Request = Athena::Framework::Request
  {% else %}
    # Represents the type of the *request* parameter within an `ART::Route::Condition`.
    #
    # Will be an [ATH::Request](/Framework/Request) instance if used within the Athena Framework, otherwise [HTTP::Request](https://crystal-lang.org/api/HTTP/Request.html).
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
  # A custom *route_provider* type may be provided to compile the routes into a different provider.
  # By default, the default global `ART::RouteProvider` is used.
  def self.compile(routes : ART::RouteCollection, *, route_provider : ART::RouteProvider.class = ART::RouteProvider) : Nil
    route_provider.compile routes
  end
end
