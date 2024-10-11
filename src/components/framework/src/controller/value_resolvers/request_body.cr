@[ADI::Register(tags: [{name: ATHR::Interface::TAG, priority: 105}])]
# Attempts to resolve the value of any parameter with the `ATHA::MapRequestBody` annotation by
# deserializing the request body into an object of the type of the related parameter.
# Also handles running any validations defined on it, if it is `AVD::Validatable`.
# Requires the type of the related parameter to include either `ASR::Serializable` or `JSON::Serializable`.
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
  include Athena::Framework::Controller::ValueResolvers::Interface::Typed(Athena::Serializer::Serializable, JSON::Serializable)

  # Enables the `ATHR::RequestBody` resolver for the parameter this annotation is applied to.
  # See the related resolver documentation for more information.
  configuration ::Athena::Framework::Annotations::MapRequestBody

  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface,
  ); end

  # :inherit:
  def resolve(request : ATH::Request, parameter : ATH::Controller::ParameterMetadata)
    return unless parameter.annotation_configurations.has? ATHA::MapRequestBody

    if !(body = request.body) || body.peek.try &.empty?
      raise ATH::Exception::BadRequest.new "Request does not have a body."
    end

    begin
      unless object = self.map_request_body body, parameter.type
        return
      end
    rescue ex : JSON::ParseException | ASR::Exception::DeserializationException
      raise ATH::Exception::BadRequest.new "Malformed JSON payload.", cause: ex
    end

    if object.is_a? AVD::Validatable
      errors = @validator.validate object
      raise AVD::Exception::ValidationFailed.new errors unless errors.empty?
    end

    object
  end

  private def map_request_body(body : IO, klass : ASR::Serializable.class)
    @serializer.deserialize klass, body, :json
  end

  private def map_request_body(body : IO, klass : JSON::Serializable.class)
    klass.from_json body
  end

  private def map_request_body(body : IO, klass : _) : Nil
  end
end
