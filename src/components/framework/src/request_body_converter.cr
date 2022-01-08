require "./param_converter"

@[ADI::Register]
# Deserializes the request body into an object, runs any validations defined on it, then provides the object to the controller action.
# Uses the type restriction of the related controller action argument to know what type to deserialize into.
# Supports both `ASR::Serializable` and `JSON::Serializable` types.
#
# ```
# require "athena"
#
# # A type representing the structure of the request body.
# struct UserCreate
#   # Include some modules to tell Athena this type can be deserialized
#   # via the Serializer component and validated via the Valdiator component.
#   include AVD::Validatable
#   include ASR::Serializable
#
#   # Assert the user's name is not blank.
#   @[Assert::NotBlank]
#   getter first_name : String
#
#   # Assert the user's name is not blank.
#   @[Assert::NotBlank]
#   getter last_name : String
#
#   # Assert the user's email is not blank and is valid.
#   @[Assert::NotBlank]
#   @[Assert::Email(:html5)]
#   getter email : String
# end
#
# class UserController < ATH::Controller
#   @[ARTA::Post("/user")]
#   @[ATHA::View(status: :created)]
#   @[ATHA::ParamConverter("user_create", converter: ATH::RequestBodyConverter)]
#   def new_user(user_create : UserCreate) : UserCreate
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
#   "email": "dietrich.app"
# }
# ```
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
# While a valid request would return:
#
# ```json
# {
#   "first_name": "George",
#   "last_name": "Dietrich",
#   "email": "george@dietrich.app"
# }
# ```
class Athena::Framework::RequestBodyConverter < Athena::Framework::ParamConverter
  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface
  ); end

  # :inherit:
  def apply(request : ATH::Request, configuration : Configuration(ArgType)) : Nil forall ArgType
    raise ATH::Exceptions::BadRequest.new "Request has no body." unless (body = request.body)

    {% begin %}
      begin
        {% if ArgType.instance <= ASR::Serializable %}
          object = @serializer.deserialize ArgType, body, :json
        {% elsif ArgType.instance <= JSON::Serializable %}
          object = ArgType.from_json body
        {% else %}
          {% ArgType.raise "'#{@type}' cannot convert '#{ArgType}', as it is not serializable. '#{ArgType}' must include `JSON::Serializable` or `ASR::Serializable`." %}
        {% end %}
      rescue ex : JSON::ParseException | ASR::Exceptions::DeserializationException
        raise ATH::Exceptions::BadRequest.new "Malformed JSON payload.", cause: ex
      end

      if object.is_a? AVD::Validatable
        errors = @validator.validate object
        raise AVD::Exceptions::ValidationFailed.new errors unless errors.empty?
      end

      request.attributes.set configuration.name, object, ArgType
    {% end %}
  end
end
