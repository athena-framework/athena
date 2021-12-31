# Represents the type of URLs that are able to be generated via an `ART::Generator::Interface`.
enum Athena::Routing::Generator::ReferenceType
  # Includes an absolute URL including protocol, hostname, and path: `https://api.example.com/add/10/5`.
  #
  # By default the `Host` header of the request is used as the hostname, with the scheme being `https`.
  # This can be customized via the `ATH::Parameters#base_uri` parameter if used within `Athena::Framework`.
  #
  # NOTE: If the `base_uri` parameter is not set, and there is no `Host` header, the generated URL will fallback on `ABSOLUTE_PATH`.
  ABSOLUTE_URL

  # The default type, includes an absolute path from the root to the generated route: `/add/10/5`.
  ABSOLUTE_PATH

  # Returns a path relative to the path of the request.
  # For example:
  #
  # ```
  # routes = ART::RouteCollection.new
  # routes.add "one", ART::Route.new "/a/b/c/d"
  # routes.add "two", ART::Route.new "/a/b/c/"
  # routes.add "three", ART::Route.new "/a/b/"
  # routes.add "four", ART::Route.new "/a/b/c/other"
  # routes.add "five", ART::Route.new "/a/x/y"
  #
  # ART.compile routes
  #
  # context = ART::RequestContext.new path: "/a/b/c/d"
  #
  # generator = ART::Generator::URLGenerator.new context
  #
  # generator.generate "one", reference_type: :relative_path   # => ""
  # generator.generate "two", reference_type: :relative_path   # => "./"
  # generator.generate "three", reference_type: :relative_path # => "../"
  # generator.generate "four", reference_type: :relative_path  # => "other"
  # generator.generate "five", reference_type: :relative_path  # => "../../x/y"
  # ```
  RELATIVE_PATH

  # Similar to `ABSOLUTE_URL`, but reuses the current protocol: `//api.example.com/add/10/5`.
  NETWORK_PATH
end
