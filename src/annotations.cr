module Athena::Routing
  # Defines a `GET` endpoint.
  #
  # A corresponding `HEAD` endpoint is also defined.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Get(path: "/users/:id")]
  # def get_user(id : Int32) : Nil
  # end
  # ```
  annotation Get; end

  # Defines a `POST` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Post(path: "/users")]
  # def new_user : Nil
  # end
  # ```
  annotation Post; end

  # Defines a `PUT` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Put(path: "/users/:id")]
  # def update_user(id : Int32) : Nil
  # end
  # ```
  annotation Put; end

  # Defines a `PATCH` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Patch(path: "/users/:id")]
  # def partial_update_user(id : Int32) : Nil
  # end
  # ```
  annotation Patch; end

  # Defines a `DELETE` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Delete(path: "/users/:id")]
  # def delete_user(id : Int32) : Nil
  # end
  # ```
  annotation Delete; end

  # Defines a `LINK` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Link(path: "/users/:id")]
  # def link_user(id : Int32) : Nil
  # end
  # ```
  annotation Link; end

  # Applies an `ART::ParamConverterInterface` to a given argument.
  #
  # See `ART::ParamConverterInterface` for more information on defining a param converter.
  #
  # ## Fields
  #
  # * name : `String` - The name of the argument that should be converted, may also be provided as the first positional argument.
  # * converter : `ART::ParamConverterInterface.class` - The `ART::ParamConverterInterface` that should be used to convert this argument.
  #
  # ## Example
  #
  # ```
  # @[ART::Get(path: "/multiply/:num")]
  # @[ART::ParamConverter("num", converter: MultiplyConverter)]
  # def multiply(num : Int32) : Int32
  #   num
  # end
  # ```
  annotation ParamConverter; end

  # Apply a *prefix* to all actions within `self`.  Can be a static string, but may also contain path arguments.
  #
  # ## Fields
  #
  # * prefix : `String` - The path prefix to use, may also be provided as the first positional argument.
  #
  # ## Example
  #
  # ```
  # @[ART::Prefix(prefix: "calendar")]
  # class CalendarController < ART::Controller
  #   # The route of this action would be `GET /calendar/events`.
  #   @[ART::Get(path: "events")]
  #   def events : String
  #     "events"
  #   end
  # end
  # ```
  annotation Prefix; end

  # Used to define (and configure) a query parameter tied to a given argument.
  #
  # The type of the query param is derived from the type restriction of the associated controller action argument.
  #
  # ## Usage
  #
  # The most basic usage is adding an annotation to a controller action whose name matches a controller action argument.
  # A `description` may also be included to describe what the query param is used for.
  # In the future this may be used for generating OpenAPI documentation for the related parameter.
  #
  # A non-nilable type denotes it as required.  If the parameter is not supplied, and no default value is assigned, an `ART::Exceptions::BadRequest` exception is raised.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("page", description: "What page of results to return.")] # The name can also be supplied as a named argument like `@[ART::QueryParam(name: "page")]`.
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ART.run
  #
  # # GET /?page=2 # => 2
  # # GET /        # => {"code":422,"message":"Parameter 'page' of value '' violated a constraint: 'This value should not be null.'\n"}
  # ```
  #
  # ### Key
  #
  # In the case of wanting the controller action argument to have a different name than the actual query parameter, the `key` option can be used.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("foo", key: "bar")]
  #   def index(foo : String) : String
  #     foo
  #   end
  # end
  #
  # ART.run
  #
  # # GET /?bar=value # => "value"
  # ```
  #
  # ### Optional
  #
  # A nilable type denotes it as optional.  If the parameter is not supplied, and no default value is assigned, it is `nil`.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("page")] # The name can also be supplied as a named argument like `@[ART::QueryParam(name: "page")]`.
  #   def index(page : Int32?) : Int32?
  #     page
  #   end
  # end
  #
  # ART.run
  #
  # # GET /          # => null
  # # GET /?page=2   # => 2
  # # GET /?page=bar # => {"code":400,"message":"Required parameter 'page' with value 'bar' could not be converted into a valid '(Int32 | Nil)'."}
  # ```
  #
  # ### Strict
  #
  # By default, parameters are validated strictly; this means an `ART::Exceptions::BadRequest` exception is raised when the value is considered invalid.
  # Such as if the value does not satisfy the parameter's [requirements](#requirements), it's a required parameter and was not provided,
  # or could not be converted into the desired type.
  #
  # An example of this is in the first [usage](#usage) example.  A 400 bad request was returned when the required parameter was not provided.
  #
  # When strict mode is disabled, the default value (or `nil`) will be used instead of raising an exception if the actual value is invalid.
  #
  # NOTE: When setting `strict: false`, the related controller action argument must be nilable or have a default value.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("page", strict: false)]
  #   def index(page : Int32?) : Int32?
  #     page
  #   end
  # end
  #
  # ART.run
  #
  # # GET /          # => null
  # # GET /?page=2   # => 2
  # # GET /?page=bar # => null
  # ```
  #
  # If strict mode is enabled _AND_ the argument is nilable, the value will only be checked strictly if it is provided
  # and does not meet the parameter's requirements, or could not be converted.
  # If it was not provided at all, `nil`, or the default value will be used.
  #
  # ### Requirements
  #
  # It's a common practice to validate incoming values before they reach the controller action.
  # `ART::QueryParam` supports doing just that.
  # It supports validating the value against a `Regex` pattern, an `AVD::Constraint`, or an array of `AVD::Constraint`s.
  #
  # The value is only considered valid if it satisfies the defined requirements.
  # If the value does not match, and [strict](#strict) mode is enabled, a 422 response is returned;
  # otherwise `nil`, or the default value is used instead.
  #
  # #### Regex
  #
  # The most basic form of validation is a `Regex` pattern that asserts a value matches the provided pattern.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("page", requirements: /\d{2}/)]
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ART.run
  #
  # # GET /          # => {"code":422,"message":"Parameter 'page' of value '' violated a constraint: 'This value should not be null.'\n"}
  # # GET /?page=10  # => 10
  # # GET /?page=bar # => {"code":400,"message":"Required parameter 'page' with value 'bar' could not be converted into a valid 'Int32'."}
  # # GET /?page=5   # => {"code":422,"message":"Parameter 'page' of value '5' violated a constraint: 'Parameter 'page' value does not match requirements: (?-imsx:^(?-imsx:\\d{2})$)'\n"}
  # ```
  #
  # #### Constraint(s)
  #
  # In some cases validating a value may require more logic than is possible via a regular expression.
  # A parameter's requirements can also be set to a specific, or array of, `Assert` `AVD::Constraint` annotations.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("page", requirements: @[Assert::PositiveOrZero])]
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ART.run
  #
  # # GET /?page=2  # => 2
  # # GET /?page=-5 # => {"code":422,"message":"Parameter 'page' of value '-9' violated a constraint: 'This value should be positive or zero.'\n"}
  # ```
  #
  # ### Map
  #
  # By default, the parameter's requirements are applied against the resulting value, which makes sense when working with scalar values.
  # However, if the parameter is an `Array` of values, then it may make more sense to run the validations against each item in that array,
  # as opposed to on the whole array itself.
  #
  # This behavior can be enabled by using the `map: true` option, which essentially wraps all the requirements within an `AVD::Constraints::All` constraint.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("ids", map: true, requirements: [@[Assert::Positive], @[Assert::Range(-3..10)]])]
  #   def index(ids : Array(Int32)) : Array(Int32)
  #     ids
  #   end
  # end
  #
  # ART.run
  #
  # # GET /               # => {"code":422,"message":"Parameter 'ids' of value '' violated a constraint: 'This value should not be null.'\n"}
  # # GET /?ids=10&ids=2  # => [10,2]
  # # GET /?ids=10&ids=-2 # => {"code":422,"message":"Parameter 'ids[1]' of value '-2' violated a constraint: 'This value should be positive.'\n"}
  # ```
  #
  # ### Incompatibles
  #
  # Incompatibles represent the parameters that can't be present at the same time.
  #
  # ```
  # class ExampleController < ART::Controller
  #   @[ART::Get("/")]
  #   @[ART::QueryParam("bar")]
  #   @[ART::QueryParam("foo", incompatibles: ["bar"])]
  #   def index(foo : String?, bar : String?) : String
  #     "#{foo}-#{bar}"
  #   end
  # end
  #
  # ART.run
  #
  # # GET /?bar=bar         # => "-bar"
  # # GET /?foo=foo         # => "foo-"
  # # GET /?foo=foo&bar=bar # => {"code":400,"message":"Parameter 'foo' is incompatible with parameter 'bar'."}
  # ```
  annotation QueryParam; end

  # Represents a form data request parameter.
  #
  # See `ART::QueryParam` for configuration options/arguments.
  #
  # NOTE: The entire request body is consumed to parse the form data.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ART::Controller
  #   @[ART::Post(path: "/login")]
  #   @[ART::RequestParam("username")]
  #   @[ART::RequestParam("password")]
  #   def login(username : String, password : String) : Nil
  #     # ...
  #   end
  # end
  #
  # ART.run
  #
  # # POST /login, body: "username=George&password=abc123"
  # ```
  annotation RequestParam; end

  # Defines an endpoint with an arbitrary `HTTP` method.  Can be used for defining non-standard `HTTP` method routes.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * method : `String` - The `HTTP` method to use for the endpoint.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Route("/some/path", method: "TRACE")]
  # def trace_route : Nil
  # end
  # ```
  annotation Route; end

  # Defines an `UNLINK` endpoint.
  #
  # ## Fields
  #
  # * path : `String` - The path for the endpoint, may also be provided as the first positional argument.
  # * constraints : `Hash(String, Regex)` - A mapping between a route's path parameters and its constraints.
  #
  # ## Example
  #
  # ```
  # @[ART::Unlink(path: "/users/:id")]
  # def unlink_user(id : Int32) : Nil
  # end
  # ```
  annotation Unlink; end

  # Configures how the endpoint should be rendered.
  #
  # See `ART::Action::ViewContext`.
  #
  # ## Fields
  #
  # * status : `HTTP::Status` - The `HTTP::Status` the endpoint should return.  Defaults to `HTTP::Status::OK` (200).
  # * serialization_groups : `Array(String)?` - The serialization groups to use for this route as part of `ASR::ExclusionStrategies::Groups`.
  # * validation_groups : `Array(String)?` - Groups that should be used to validate any objects related to this route; see `AVD::Constraint@validation-groups`.
  # * emit_nil : `Bool` - If `nil` values should be serialized.  Defaults to `false`.
  #
  # ## Example
  #
  # ```
  # @[ART::Post(path: "/publish/:id")]
  # @[ART::View(status: :accepted, serialization_groups: ["default", "detailed"])]
  # def publish(id : Int32) : Article
  #   article = Article.find id
  #   article.published = true
  #   article
  # end
  # ```
  annotation View; end
end
