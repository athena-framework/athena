# Contains all the `Athena::Framework` based annotations.
# See each annotation for more information.
module Athena::Framework::Annotations
  # Applies an `ATH::ParamConverter` to a given argument.
  #
  # See `ATH::ParamConverter` for more information on defining a param converter.
  #
  # ## Fields
  #
  # * name : `String` - The name of the argument that should be converted, may also be provided as the first positional argument.
  # * converter : `ATH::ParamConverter.class` - The `ATH::ParamConverter` that should be used to convert this argument.
  #
  # ## Example
  #
  # ```
  # @[ARTA::Get(path: "/multiply/{num}")]
  # @[ATHA::ParamConverter("num", converter: MultiplyConverter)]
  # def multiply(num : Int32) : Int32
  #   num
  # end
  # ```
  annotation ParamConverter; end

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
  # A non-nilable type denotes it as required. If the parameter is not supplied, and no default value is assigned, an `ATH::Exceptions::UnprocessableEntity` exception is raised.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("page", description: "What page of results to return.")] # The name can also be supplied as a named argument like `@[ATHA::QueryParam(name: "page")]`.
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?page=2 # => 2
  # # GET / # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'page' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "page",
  # #       "message":  "This value should not be null.",
  # #       "code":     "c7e77b14-744e-44c0-aa7e-391c69cc335c"
  # #     }
  # #   ]
  # # }
  # ```
  #
  # ### Key
  #
  # In the case of wanting the controller action argument to have a different name than the actual query parameter, the `key` option can be used.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("foo", key: "bar")]
  #   def index(foo : String) : String
  #     foo
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?bar=value # => "value"
  # ```
  #
  # ### Optional
  #
  # A nilable type denotes it as optional. If the parameter is not supplied, and no default value is assigned, it is `nil`.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("page")] # The name can also be supplied as a named argument like `@[ATHA::QueryParam(name: "page")]`.
  #   def index(page : Int32?) : Int32?
  #     page
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /          # => null
  # # GET /?page=2   # => 2
  # # GET /?page=bar # =>
  # # {
  # #   "code":    400,
  # #   "message":"Required parameter 'page' with value 'bar' could not be converted into a valid '(Int32 | Nil)'."
  # # }
  # ```
  #
  # ### Strict
  #
  # By default, parameters are validated strictly; this means an `ATH::Exceptions::BadRequest` exception is raised when the value is considered invalid.
  # Such as if the value does not satisfy the parameter's [requirements](#requirements), it's a required parameter and was not provided,
  # or could not be converted into the desired type.
  #
  # An example of this is in the first [usage](#usage) example. A 400 bad request was returned when the required parameter was not provided.
  #
  # When strict mode is disabled, the default value (or `nil`) will be used instead of raising an exception if the actual value is invalid.
  #
  # NOTE: When setting `strict: false`, the related controller action argument must be nilable or have a default value.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("page", strict: false)]
  #   def index(page : Int32?) : Int32?
  #     page
  #   end
  # end
  #
  # ATH.run
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
  # `ATHA::QueryParam` supports doing just that.
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
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("page", requirements: /\d{2}/)]
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?page=10  # => 10
  # # GET /?page=bar # => {"code":400,}
  #
  # # GET /?page=bar # =>
  # # {
  # #   "code":    400,
  # #   "message":"Required parameter 'page' with value 'bar' could not be converted into a valid 'Int32'."
  # # }
  #
  # # GET / # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'page' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "page",
  # #       "message":  "This value should not be null.",
  # #       "code":     "c7e77b14-744e-44c0-aa7e-391c69cc335c"
  # #     }
  # #   ]
  # # }
  #
  # # GET /?page=5 # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'page' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "page",
  # #       "message":  "Parameter 'page' value does not match requirements: (?-imsx:^(?-imsx:\\d{2})$)",
  # #       "code":     "108987a0-2d81-44a0-b8d4-1c7ab8815343"
  # #     }
  # #   ]
  # # }
  # ```
  #
  # #### Constraint(s)
  #
  # In some cases validating a value may require more logic than is possible via a regular expression.
  # A parameter's requirements can also be set to a specific, or array of, `Assert` `AVD::Constraint` annotations.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("page", requirements: @[Assert::PositiveOrZero])]
  #   def index(page : Int32) : Int32
  #     page
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?page=2  # => 2
  # # GET /?page=-5 # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'page' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "page",
  # #       "message": "This value should be positive or zero.",
  # #       "code": "e09e52d0-b549-4ba1-8b4e-420aad76f0de"
  # #     }
  # #   ]
  # # }
  # ```
  #
  # See the [external documentation](/components/validator/) for more information.
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
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("ids", map: true, requirements: [@[Assert::Positive], @[Assert::Range(-3..10)]])]
  #   def index(ids : Array(Int32)) : Array(Int32)
  #     ids
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?ids=10&ids=2  # => [10,2]
  # # GET / # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'ids' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "ids",
  # #       "message":  "This value should not be null.",
  # #       "code":     "c7e77b14-744e-44c0-aa7e-391c69cc335c"
  # #     }
  # #   ]
  # # }
  #
  # # GET /?ids=10&ids=-2 # =>
  # # {
  # #   "code":    422,
  # #   "message": "Parameter 'ids' is invalid.",
  # #   "errors":  [
  # #     {
  # #       "property": "ids[1]",
  # #       "message":  "message": "This value should be positive.",
  # #       "code":     "code": "a221096d-d125-44e8-a865-4270379ac11a"
  # #     }
  # #   ]
  # # }
  # ```
  #
  # ### Incompatibles
  #
  # Incompatibles represent the parameters that can't be present at the same time.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Get("/")]
  #   @[ATHA::QueryParam("bar")]
  #   @[ATHA::QueryParam("foo", incompatibles: ["bar"])]
  #   def index(foo : String?, bar : String?) : String
  #     "#{foo}-#{bar}"
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /?bar=bar         # => "-bar"
  # # GET /?foo=foo         # => "foo-"
  # # GET /?foo=foo&bar=bar # =>
  # # {
  # #   "code":    400,
  # #   "message":"Parameter 'foo' is incompatible with parameter 'bar'."
  # # }
  # ```
  #
  # ### Param Converters
  #
  # While Athena is able to auto convert query parameters from their `String` representation to `Bool`, or `Number` types, it is unable to do that for more complex types, such as `Time`.
  # In such cases an `ATH::ParamConverter` is required.
  #
  # For simple converters that do not require any additional configuration, you can just specify the `ATH::ParamConverter.class` you wish to use for this query parameter.
  # Default and nilable values work as they do when not using a converter.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ATHA::QueryParam("start_time", converter: ATH::TimeConverter)]
  #   @[ARTA::Get("/time")]
  #   def time(start_time : Time = Time.utc) : String
  #     "Starting at: #{start_time}"
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /time                                 # => "Starting at: 2020-11-25 20:29:55 UTC"
  # # GET /time?start_time=2020-04-07T12:34:56Z # => "Starting at: 2020-04-07 12:34:56 UTC"
  # ```
  #
  # #### Extra Configuration
  #
  # In some cases a param converter may require [additional configuration][Athena::Framework::ParamConverter].
  # In this case a `NamedTuple` may be provided as the value of `converter`.
  # The named tuple must contain a `name` key that represents the `ATH::ParamConverter.class` you wish to use for this query parameter.
  # Any additional key/value pairs will be passed to the param converter.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ATHA::QueryParam("start_time", converter: {name: ATH::TimeConverter, format: "%Y--%m//%d  %T"})]
  #   @[ARTA::Get("/time")]
  #   def time(start_time : Time) : String
  #     "Starting at: #{start_time}"
  #   end
  # end
  #
  # ATH.run
  #
  # # GET /time?start_time="2020--04//07  12:34:56" # => "Starting at: 2020-04-07 12:34:56 UTC"
  # ```
  #
  # NOTE: The dedicated `ATHA::ParamConverter` annotation may be used as well, just be sure to give it and the query parameter the same name.
  annotation QueryParam; end

  # Represents a form data request parameter.
  #
  # See `ATHA::QueryParam` for configuration options/arguments.
  #
  # WARNING: The entire request body is consumed to parse the form data.
  #
  # ```
  # require "athena"
  #
  # class ExampleController < ATH::Controller
  #   @[ARTA::Post(path: "/login")]
  #   @[ATHA::RequestParam("username")]
  #   @[ATHA::RequestParam("password")]
  #   def login(username : String, password : String) : Nil
  #     # ...
  #   end
  # end
  #
  # ATH.run
  #
  # # POST /login, body: "username=George&password=abc123"
  # ```
  annotation RequestParam; end

  ACF.configuration_annotation Athena::Framework::Annotations::View,
    status : HTTP::Status? = nil,
    serialization_groups : Array(String)? = nil,
    validation_groups : Array(String)? = nil,
    emit_nil : Bool? = nil

  # Configures how the `ATH::View::ViewHandlerInterface` should render the related controller action.
  #
  # ## Fields
  #
  # * status : `HTTP::Status` - The `HTTP::Status` the endpoint should return. Defaults to `HTTP::Status::OK` (200).
  # * serialization_groups : `Array(String)?` - The serialization groups to use for this route as part of `ASR::ExclusionStrategies::Groups`.
  # * validation_groups : `Array(String)?` - Groups that should be used to validate any objects related to this route; see `AVD::Constraint@validation-groups`.
  # * emit_nil : `Bool` - If `nil` values should be serialized. Defaults to `false`.
  #
  # ## Example
  #
  # ```
  # @[ARTA::Post(path: "/publish/{id}")]
  # @[ATHA::View(status: :accepted, serialization_groups: ["default", "detailed"])]
  # def publish(id : Int32) : Article
  #   article = Article.find id
  #   article.published = true
  #   article
  # end
  # ```
  #
  # See the [external documentation](/components/serializer/) for more information.
  annotation View; end
end
