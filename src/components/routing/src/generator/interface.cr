# Allows generating a URL for a given `ART::Route`.
#
# ```
# routes = ART::RouteCollection.new
# routes.add "blog_show", ART::Route.new "/blog/{slug}"
#
# generator = ART::Generator::URLGenerator.new context
# generator.generate "blog_show", slug: "bar-baz", source: "Crystal" # => "/blog/bar-baz?source=Crystal"
# ```
#
# ## Parameter Default Values
#
# By default parameters with a default value the same as the provided parameter will be excluded from the generated URL.
# For example:
#
# ```
# routes = ART::RouteCollection.new
# routes.add "articles", ART::Route.new "/articles/{page}", {"page" => "1"}
#
# ART.compile routes
#
# generator = ART::Generator::URLGenerator.new ART::RequestContext.new
# generator.generate "articles"          # => "/articles"
# generator.generate "articles", page: 1 # => "/articles"
# generator.generate "articles", page: 2 # => "/articles/2"
# ```
#
# If you want to always include a parameter, add a `!` before the `ART::Route#path`, for example:
#
# ```
# routes.add "users", ART::Route.new "/users/{!page}", {"page" => "1"}
#
# generator.generate "users"          # => "/users/1"
# generator.generate "users", page: 1 # => "/users/1"
# generator.generate "users", page: 2 # => "/users/2"
# ```
#
# ## URL Types
#
# `Athena::Routing` supports various ways to generate the URL, via the *reference_type* parameter.
# See `ART::Generator::ReferenceType` for description/examples of the possible types.
module Athena::Routing::Generator::Interface
  include Athena::Routing::RequestContextAwareInterface

  # Generates a URL for the provided *route*, optionally with the provided *params* and *reference_type*.
  abstract def generate(route : String, params : Hash(String, String?) = Hash(String, String?).new, reference_type : ART::Generator::ReferenceType = :absolute_path) : String

  # :ditto:
  abstract def generate(route : String, reference_type : ART::Generator::ReferenceType = :absolute_path, **params) : String
end
