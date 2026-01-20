# Provides an object-oriented way to represent an HTTP route,
# including the path, methods, schemes, host, and/or conditions required for it to match.
#
# Ultimately, `ART::Route`s are compiled into `ART::CompiledRoute` that represents an immutable
# snapshot of a route, along with `ART::CompiledRoute::Token`s representing each route parameter.
#
# By default, a route is very liberal in regards to what allows when matching.
# E.g. Matching anything that matches the `path`, but with any HTTP method and any scheme.
# The `methods` and `schemes` properties can be used to restrict which methods/schemes the route allows.
#
# ```
# # This route will only handle `https` `POST` requests to `/path`.
# route1 = ART::Route.new "/path", schemes: "https", methods: "POST"
#
# # This route will handle `http` or `ftp` `GET`/`PATCH` requests to `/path`.
# route2 = ART::Route.new "/path", schemes: {"https", "ftp"}, methods: {"GET", "PATCH"}
# ```
#
# ## Expressions
#
# In some cases you may want to match a route using arbitrary dynamic runtime logic.
# An example use case for this could be checking a request header, or anything else on the underlying `ART::RequestContext` and/or `ART::Request` instance.
# The `condition` property can be used for just this purpose:
#
# ```
# route = ART::Route.new "/contact"
# route.condition do |context, request|
#   request.headers["user-agent"].includes? "Firefox"
# end
# ```
#
# This route would only match requests whose `user-agent` header includes `Firefox`.
# Be sure to also handle cases where headers may not be set.
#
# WARNING: Route conditions are _NOT_ taken into consideration when generating routes via an `ART::Generator::Interface`.
#
# ## Parameters
#
# Route parameters represent variable portions within a route's `path`.
# Parameters are uniquely named placeholders wrapped within curly braces.
# For example, `/blog/{slug}` includes a `slug` parameter.
# Routes can have more than one parameter, but each one may only map to a single value.
# Parameter placeholders may also be included with static portions for a string, such as `/blog/posts-about-{category}`.
# This can be useful for supporting format based URLs, such as `/users.json` or `/users.csv` via a `/users.{_format}` path.
#
# ### Parameter Validation
#
# By default, a placeholder is happy to accept any value.
# However in most cases you will want to restrict which values it allows, such as ensuring only numeric digits are allowed for a `page` parameter.
# Parameter validation also allows multiple routes to have variable portions within the same location.
# I.e. allowing `/blog/{slug}` and `/blog/{page}` to co-exist, which is a limitation for some other Crystal routers.
#
# The `requirements` property accepts a `Hash(String, String | Regex)` where the keys are the name of the parameter and the value is a pattern
# in which the value must match for the route to match. The value can either be a string for exact matches, or a `Regex` for more complex patterns.
#
# Route parameters may also be inlined within the `path` by putting the pattern within `<>`, instead of providing it as a dedicated argument.
# For example, `/blog/{page<\\d+>}` (note we need to escape the `\` within a string literal).
#
# ```
# routes = ART::RouteCollection.new
# routes.add "blog_list", ART::Route.new "/blog/{page}", requirements: {"page" => /\d+/}
# routes.add "blog_show", ART::Route.new "/blog/{slug}"
#
# matcher.match "/blog/foo" # => ART::Parameters{"_route" => "blog_show", "slug" => "foo"}
# matcher.match "/blog/10"  # => ART::Parameters{"_route" => "blog_list", "page" => "10"}
# ```
#
# TIP: Checkout `ART::Requirement` for a set of common, helpful requirement regexes.
#
# ### Optional Parameters
#
# By default, all parameters are required, meaning given the path `/blog/{page}`, `/blog/10` would match but `/blog` would _NOT_ match.
# Parameters can be made optional by providing a default value for the parameter, for example:
#
# ```
# ART::Route.new "/blog/{page}", {"page" => 1}, {"page" => /\d+/}
#
# # ...
#
# matcher.match "/blog" # => ART::Parameters{"_route" => "blog_list", "page" => "1"}
# ```
#
# CAUTION: More than one parameter may have a default value, but everything after an optional parameter must also be optional.
# For example within `/{page}/blog`, `page` will always be required and `/blog` will _NOT_ match.
#
# `defaults` may also be inlined within the `path` by putting the value after a `?`.
# This is also compatible with `requirements`, allowing both to be defined within a path.
# For example `/blog/{page<\\d+>?1}`.
#
# TIP: The default value for a parameter may also be `nil`, with the inline syntax being adding a `?` with no following value, e.g. `{page?}`.
# Be sure to update any type restrictions to be nilable as well.
#
# ### Priority Parameter
#
# When determining which route should match, the first matching route will win.
# For example, if two routes were added with variable parameters in the same location, the first one that was added would match regardless of what their requirements are.
# In most cases this will not be a problem, but in some cases you may need to ensure a particular route is checked first.
#
# ### Special Parameters
#
# The routing component comes with a few standardized parameters that have special meanings.
# These parameters could be leveraged within the underlying implementation, but are not directly used within the routing component other than for matching.
#
# * `_format` - Could be used to set the underlying format of the request, as well as determining the [content-type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type) of the response.
# * `_fragment` - Represents the fragment identifier when generating a URL. E.g. `/article/10#summary` with the fragment being `summary`.
# * `_locale` - Could be used to set the underlying locale of the `ART::Request` based on which route is matched.
# * `_query` - Used to explicitly add [query parameters](/Routing/Generator/Interface/#Athena::Routing::Generator::Interface--query-parameters) to the generated URL.
#
# ```
# ART::Route.new(
#   "/articles/{_locale}/search.{_format}",
#   {
#     "_locale" => "en",
#     "_format" => "html",
#   },
#   {
#     "_locale" => /en|fr/,
#     "_format" => /html|xml/,
#   }
# )
# ```
#
# This route supports `en` and `fr` locales in either `html` or `xml` formats with a default of `en` and `html`.
#
# TIP: The trailing `.` is optional if the parameter to the right has a default.
# E.g. `/articles/en/search` would match with a format of `html` but `/articles/en/search.xml` would be required for matching non-default formats.
#
# ### Extra Parameters
#
# The defaults defined within a route do not all need to be present as route parameters.
# This could be useful to provide extra context to the controller that should handle the request.
#
# ```
# ART::Route.new "/blog/{page}", {"page" => 1, "title" => "Hello world!"}
# ```
#
# ### Slash Characters in Route Parameters
#
# By default, route parameters may include any value except a `/`, since that's the character used to separate the different portions of the URL.
# Route parameter matching logic may be made more permissive by using a more liberal regex, such as `.+`, for example:
#
# ```
# ART::Route.new "/share/{token}", requirements: {"token" => /.+/}
# ```
#
# Special parameters should _NOT_ be made more permissive.
# For example, if the pattern is `/share/{token}.{_format}` and `{token}` allows any character, the `/share/foo/bar.json` URL will consider `foo/bar.json` as the token and the format will be empty.
# This can be solved by replacing the `.+` requirement with `[^.]+` to allow any character except dots.
#
# Related to this, allowing multiple parameters to accept `/` may also lead to unexpected results.
#
# ## Sub-Domain Routing
#
# The `host` property can be used to require the HTTP [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header to match this value in order for the route to match.
#
# ```
# mobile_homepage = ART::Route.new "/", host: "m.example.com"
# homepage = ART::Route.new "/"
# ```
#
# In this example, both routes match the same path, but one requires a specific hostname.
# The `host` parameter can also be used as route parameters, including `defaults` and `requirements` support:
#
# ```
# mobile_homepage = ART::Route.new(
#   "/",
#   {"subdomain" => "m"},
#   {"subdomain" => /m|mobile/},
#   "{subdomain}.example.com"
# )
# homepage = ART::Route.new "/"
# ```
#
# TIP: Inline defaults and requirements also works for `host` values, `"{subdomain<m|mobile>?m}.example.com"`.
class Athena::Routing::Route
  # Represents the callback proc used to dynamically determine if a route should be matched.
  # See [Routing Expressions][Athena::Routing::Route--expressions] for more information.
  alias Condition = Proc(ART::RequestContext, ART::Request, Bool)

  # Returns the URL that this route will handle.
  # See [Routing Parameters][Athena::Routing::Route--parameters] for more information.
  getter path : String

  # Returns the default values of a route's parameters if they were not provided in the request.
  # See [Optional Parameters][Athena::Routing::Route--optional-parameters] for more information.
  getter defaults : ART::Parameters = ART::Parameters.new

  # Returns a hash representing the requirements the route's parameters must match in order for this route to match.
  # See [Parameter Validation][Athena::Routing::Route--parameter-validation] for more information.
  getter requirements : Hash(String, Regex) = Hash(String, Regex).new

  # Returns the hostname that the HTTP [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header must match in order for this route to match.
  # See [Sub-Domain Routing][Athena::Routing::Route--sub-domain-routing] for more information.
  getter host : String?

  # Returns the set of valid HTTP methods that this route supports.
  # See [ART::Route][] for more information.
  getter methods : Set(String)?

  # Returns the optional `ART::Route::Condition` callback used to determine if this route should match.
  # See [Routing Expressions][Athena::Routing::Route--expressions] for more information.
  property condition : Condition? = nil

  # TODO: Don't think we actually know what this is:

  # Returns the set of valid URI schemes that this route supports.
  # See [ART::Route][] for more information.
  getter schemes : Set(String)? = nil

  @compiled_route : ART::CompiledRoute? = nil

  def initialize(
    @path : String,
    defaults : Hash(String, _) | ART::Parameters = Hash(String, String?).new,
    requirements : Hash(String, Regex | String) = Hash(String, Regex | String).new,
    host : String | Regex | Nil = nil,
    methods : String | Enumerable(String) | Nil = nil,
    schemes : String | Enumerable(String) | Nil = nil,
    @condition : ART::Route::Condition? = nil,
  )
    self.path = @path
    self.add_defaults defaults
    self.add_requirements requirements
    self.host = host unless host.nil?
    self.methods = methods unless methods.nil?
    self.schemes = schemes unless schemes.nil?
  end

  # :nodoc:
  def_equals @path, @defaults, @requirements, @host, @methods, @schemes

  # :nodoc:
  def_clone

  # Sets the optional `ART::Route::Condition` callback used to determine if this route should match.
  #
  # ```
  # route = ART::Route.new "/foo"
  # route.condition do |context, request|
  #   request.headers["user-agent"].includes? "Firefox"
  # end
  # ```
  #
  # See [Routing Expressions][Athena::Routing::Route--expressions] for more information.
  def condition(&@condition : ART::RequestContext, ART::Request -> Bool) : self
    self
  end

  # Sets the hostname that the HTTP [host](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Host) header must match in order for this route to match to the provided *pattern*.
  # See [Sub-Domain Routing][Athena::Routing::Route--sub-domain-routing] for more information.
  def host=(pattern : String | Regex) : self
    @host = self.extract_inline_defaults_and_requirements pattern
    @compiled_route = nil

    self
  end

  # Sets the path required for this route to match to the provided *pattern*.
  def path=(pattern : String) : self
    pattern = self.extract_inline_defaults_and_requirements pattern
    @path = "/#{pattern.strip.lstrip '/'}"
    @compiled_route = nil

    self
  end

  # Sets the set of valid URI *scheme(s)* that this route supports.
  # See [ART::Route][] for more information.
  def schemes=(schemes : String | Enumerable(String)) : self
    schemes = schemes.is_a?(String) ? {schemes} : schemes

    schemes_set = (@schemes ||= Set(String).new)
    schemes_set.clear
    schemes.each { |s| schemes_set << s.downcase }

    @compiled_route = nil

    self
  end

  # Returns `true` if this route allows the provided *scheme*, otherwise `false`.
  def has_scheme?(scheme : String) : Bool
    !!@schemes.try &.includes? scheme.downcase
  end

  # Sets the set of valid HTTP *method(s)* that this route supports.
  # See [ART::Route][] for more information.
  def methods=(methods : String | Enumerable(String)) : self
    methods = methods.is_a?(String) ? {methods} : methods

    methods_set = (@methods ||= Set(String).new)
    methods_set.clear
    methods.each { |m| methods_set << m.upcase }

    @compiled_route = nil

    self
  end

  # Compiles and returns an `ART::CompiledRoute` representing this route.
  # The route is only compiled once and future calls to this method will return the same compiled route,
  # assuming no changes were made to this route in between.
  def compile : CompiledRoute
    @compiled_route ||= ART::RouteCompiler.compile self
  end

  # Returns `true` if this route has a default with the provided *key*, otherwise `false`.
  def has_default?(key : String) : Bool
    !!@defaults.try &.has_key?(key)
  end

  # Returns the default with the provided *key* as a `String`, if any.
  def default(key : String) : String?
    @defaults[key]?
  end

  # Returns the default with the provided *key* casted to the provided *type*, if any.
  def default(key : String, type : T.class) : T? forall T
    @defaults.get?(key, T)
  end

  # Sets the default values of a route's parameters if they were not provided in the request to the provided *defaults*.
  # See [Optional Parameters][Athena::Routing::Route--optional-parameters] for more information.
  def defaults=(defaults : Hash(String, _)) : self
    @defaults = ART::Parameters.new

    self.add_defaults defaults
  end

  # :ditto:
  def defaults=(defaults : ART::Parameters) : self
    @defaults = ART::Parameters.new

    self.add_defaults defaults
  end

  # Adds the provided *defaults*, overriding previously set values.
  def add_defaults(defaults : Hash(String, _)) : self
    if defaults.has_key?("_locale") && self.localized?
      defaults.delete "_locale"
    end

    defaults.each do |key, value|
      @defaults[key] = value
    end

    @compiled_route = nil

    self
  end

  # :ditto:
  def add_defaults(defaults : ART::Parameters) : self
    if defaults.has_key?("_locale") && self.localized?
      defaults.delete "_locale"
    end

    defaults.each do |key, value|
      @defaults[key] = value
    end

    @compiled_route = nil

    self
  end

  # Sets the default with the provided *key* to the provided *value*.
  def set_default(key : String, value) : self
    if "_locale" == key && self.localized?
      return self
    end

    @defaults[key] = value
    @compiled_route = nil

    self
  end

  # Returns `true` if this route has a requirement with the provided *key*, otherwise `false`.
  def has_requirement?(key : String) : Bool
    !!@requirements.try &.has_key?(key)
  end

  # Returns the requirement with the provided *key*, if any.
  def requirement(key : String) : Regex?
    @requirements[key]?
  end

  # Sets the hash representing the requirements the route's parameters must match in order for this route to match to the provided *requirements*.
  # See [Parameter Validation][Athena::Routing::Route--parameter-validation] for more information.
  def requirements=(requirements : Hash(String, Regex | String)) : self
    @requirements.clear

    self.add_requirements requirements
  end

  # Adds the provided *requirements*, overriding previously set values.
  def add_requirements(requirements : Hash(String, Regex | String)) : self
    if requirements.has_key?("_locale") && self.localized?
      requirements.delete "_locale"
    end

    requirements.each do |key, regex|
      @requirements[key] = self.sanitize_requirement key, regex
    end

    @compiled_route = nil

    self
  end

  # Sets the requirement with the provided *key* to the provided *value*.
  def set_requirement(key : String, requirement : Regex | String) : self
    if "_locale" == key && self.localized?
      return self
    end

    @requirements[key] = self.sanitize_requirement key, requirement

    @compiled_route = nil

    self
  end

  private def extract_inline_defaults_and_requirements(pattern : Regex) : String
    self.extract_inline_defaults_and_requirements pattern.source
  end

  private def extract_inline_defaults_and_requirements(pattern : String) : String
    return pattern if !pattern.includes?('?') && !pattern.includes?('<')

    pattern.gsub /\{(!?)(\w++)(<.*?>)?(\?[^\}]*+)?\}/ do |_, match|
      if requirement = match[3]?.presence
        self.set_requirement match[2], requirement[1...-1]
      end

      if match[4]?.presence
        self.set_default match[2], "?" != match[4] ? match[4][1..] : nil
      end

      "{#{match[1]}#{match[2]}}"
    end
  end

  private def sanitize_requirement(key : String, pattern : Regex) : Regex
    self.sanitize_requirement key, pattern.source
  end

  private def sanitize_requirement(key : String, pattern : String) : Regex
    unless pattern.empty?
      if p = pattern.lchop? '^'
        pattern = p
      elsif p = pattern.lchop? "\\A"
        pattern = p
      end
    end

    if p = pattern.rchop? '$'
      pattern = p
    elsif p = pattern.rchop? "\\z"
      pattern = p
    end

    pattern = "\\\\" if pattern == "\\"

    raise ArgumentError.new "Routing requirement for '#{key}' cannot be empty." if pattern.empty?

    Regex.new pattern
  end

  private def localized? : Bool
    return false unless locale = @defaults["_locale"]?
    @defaults.has_key?("_canonical_route") && self.requirement("_locale").try &.source == Regex.escape(locale)
  end
end
