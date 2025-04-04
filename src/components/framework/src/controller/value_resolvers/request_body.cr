require "uri/params/serializable"

@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 105}])]
# Attempts to resolve the value of any parameter with the `ATHA::MapRequestBody` annotation by
# deserializing the request body into an object of the type of the related parameter.
# The `ATHA::MapQueryString` annotation works similarly, but uses the request's query string instead of its body.
#
# If the object is also [AVD::Validatable](/Validator/Validatable), any validations defined on it are executed before returning the object.
# Requires the type of the related parameter to include one or more of:
#
# * `ASR::Serializable`
# * `JSON::Serializable`
# * `URI::Params::Serializable`
#
# ```
# require "athena"
#
# # A type representing the structure of the request body.
# struct UserCreate
#   # Include some modules to tell Athena this type can be deserialized and validated
#   include AVD::Validatable
#   include JSON::Serializable
#
#   # Assert the user's name is not blank.
#   @[Assert::NotBlank]
#   getter first_name : String
#
#   # Assert the user's name is not blank.
#   @[Assert::NotBlank]
#   getter last_name : String
#
#   # Assert the user's email is not blank and is a valid HTMl5 email.
#   @[Assert::NotBlank]
#   @[Assert::Email(:html5)]
#   getter email : String
# end
#
# class UserController < ATH::Controller
#   @[ARTA::Post("/user")]
#   @[ATHA::View(status: :created)]
#   def new_user(
#     @[ATHA::MapRequestBody]
#     user_create : UserCreate,
#   ) : UserCreate
#     # Use the provided UserCreate instance to create an actual User DB record.
#     # For purposes of this example, just return the instance.
#
#     user_create
#   end
# end
#
# ATH.run
# ```
#
# Making a request to the `/user` endpoint with the following payload:
#
# ```json
# {
#   "first_name": "George",
#   "last_name": "",
#   "email": "athenaframework.org"
# }
# ```
#
# TIP: This resolver also supports `application/x-www-form-urlencoded` payloads.
#
# Would return the response:
#
# ```json
# {
#   "code": 422,
#   "message": "Validation failed",
#   "errors": [
#     {
#       "property": "last_name",
#       "message": "This value should not be blank.",
#       "code": "0d0c3254-3642-4cb0-9882-46ee5918e6e3"
#     },
#     {
#       "property": "email",
#       "message": "This value is not a valid email address.",
#       "code": "ad9d877d-9ad1-4dd7-b77b-e419934e5910"
#     }
#   ]
# }
# ```
#
# While a valid request would return this response body, with a 201 status code:
#
# ```json
# {
#   "first_name": "George",
#   "last_name": "Dietrich",
#   "email": "contact@athenaframework.org"
# }
# ```
struct Athena::Framework::Controller::ValueResolvers::RequestBody
  include Athena::Framework::Controller::ValueResolvers::Interface::Typed(Athena::Serializer::Serializable, JSON::Serializable, URI::Params::Serializable)

  # Enables the `ATHR::RequestBody` resolver for the parameter this annotation is applied to based on the request's body.
  # See the related resolver documentation for more information.
  #
  # ```
  # class UserController < ATH::Controller
  #   @[ARTA::Post("/user")]
  #   def new_user(
  #     @[ATHA::MapRequestBody]
  #     user_create : UserCreateDTO,
  #   ) : UserCreateDTO
  #     user_create
  #   end
  # end
  # ```
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### accept_formats
  #
  # **Type:** `Array(String)?` **Default:** `nil`
  #
  # Allows whitelisting the allowed [request format(s)][ATH::Request::FORMATS].
  # If the `ATH::Request#content_type_format` is not included in this list, a `ATH::Exception::UnsupportedMediaType` error will be raised.
  #
  # ### validation_groups
  #
  # **Type:** `Array(String) | AVD::Constraints::GroupSequence | Nil` **Default:** `nil`
  #
  # The [validation groups](/Validator/Constraint/#Athena::Validator::Constraint--validation-groups) that should be used when validating the resolved object.
  configuration ::Athena::Framework::Annotations::MapRequestBody,
    accept_formats : Array(String)? = nil,
    validation_groups : Array(String) | AVD::Constraints::GroupSequence | Nil = nil

  # Enables the `ATHR::RequestBody` resolver for the parameter this annotation is applied to based on the request's query string.
  # See the related resolver documentation for more information.
  #
  # ```
  # class ArticleController < ATH::Controller
  #   @[ARTA::Get("/articles")]
  #   def articles(
  #     @[ATHA::MapQueryString]
  #     pagination_context : PaginationContext,
  #   ) : Array(Article)
  #     # ...
  #   end
  # end
  # ```
  #
  # # Configuration
  #
  # ## Optional Arguments
  #
  # ### validation_groups
  #
  # **Type:** `Array(String) | AVD::Constraints::GroupSequence | Nil` **Default:** `nil`
  #
  # The [validation groups](/Validator/Constraint/#Athena::Validator::Constraint--validation-groups) that should be used when validating the resolved object.
  configuration ::Athena::Framework::Annotations::MapQueryString,
    validation_groups : Array(String) | AVD::Constraints::GroupSequence | Nil = nil

  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface,
  ); end

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    validation_groups = nil

    object = if configuration = parameter.annotation_configurations[ATHA::MapQueryString]?
               validation_groups = configuration.validation_groups
               self.map_query_string request, parameter, configuration
             elsif configuration = parameter.annotation_configurations[ATHA::MapRequestBody]?
               validation_groups = configuration.validation_groups
               self.map_request_body request, parameter, configuration
             else
               return
             end

    if object.is_a? AVD::Validatable
      errors = @validator.validate object, groups: validation_groups
      raise AVD::Exception::ValidationFailed.new errors unless errors.empty?
    end

    object
  end

  private def map_query_string(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata, configuration : ATHA::MapQueryStringConfiguration)
    return unless query = request.query
    return if query.nil? && (parameter.nilable? || parameter.has_default?)

    self.deserialize_form query, parameter.type
  rescue ex : URI::SerializableError
    raise ATH::Exception::UnprocessableEntity.new ex.message.not_nil!, cause: ex
  rescue ex : URI::Error
    raise ATH::Exception::BadRequest.new "Malformed www form data payload.", cause: ex
  end

  # ameba:disable Metrics/CyclomaticComplexity:
  private def map_request_body(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata, configuration : ATHA::MapRequestBodyConfiguration)
    if !(body = request.body) || body.peek.try &.empty?
      raise ATH::Exception::BadRequest.new "Request does not have a body."
    end

    format = request.content_type_format

    if (accept_formats = configuration.accept_formats) && !accept_formats.includes? format
      raise ATH::Exception::UnsupportedMediaType.new "Unsupported format, expects one of: '#{accept_formats.join(", ")}', but got '#{format}'."
    end

    # We have to use separate deserialization methods with the case such that a type that includes multiple modules is handled as expected.
    case format
    when "form"
      self.deserialize_form body, parameter.type
    when "json"
      self.deserialize_json body, parameter.type
    else
      raise ATH::Exception::UnsupportedMediaType.new "Unsupported format."
    end
  rescue ex : JSON::SerializableError
    # JSON::Serializable seems to sometimes re-raise parse exceptions as `JSON::SerializableError`,
    # so we handle those first based on the cause.
    case cause = ex.cause
    when JSON::ParseException
      raise ATH::Exception::BadRequest.new "Malformed JSON payload.", cause: cause
    else
      raise ATH::Exception::UnprocessableEntity.new ex.message.not_nil!
    end
  rescue ex : JSON::ParseException | ASR::Exception::DeserializationException
    # Otherwise if it really is a `ParseException` we can be assured it's just malformed
    raise ATH::Exception::BadRequest.new "Malformed JSON payload.", cause: ex
  rescue ex : URI::SerializableError
    raise ATH::Exception::UnprocessableEntity.new ex.message.not_nil!, cause: ex
  rescue ex : URI::Error
    raise ATH::Exception::BadRequest.new "Malformed www form data payload.", cause: ex
  end

  private def deserialize_json(body : IO, klass : ASR::Serializable.class)
    @serializer.deserialize klass, body, :json
  end

  private def deserialize_json(body : IO, klass : JSON::Serializable.class)
    klass.from_json body
  end

  private def deserialize_json(body : IO, klass : _) : Nil
  end

  private def deserialize_form(body : IO, klass : URI::Params::Serializable.class)
    klass.from_www_form body.gets_to_end
  end

  private def deserialize_form(body : String, klass : URI::Params::Serializable.class)
    klass.from_www_form body
  end

  private def deserialize_form(body : IO | String, klass : _)
  end
end
