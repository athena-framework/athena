# @[ADI::Register]
# class Athena::Framework::RequestBodyConverter < Athena::Framework::ParamConverter
#   def initialize(
#     @serializer : ASR::SerializerInterface,
#     @validator : AVD::Validator::ValidatorInterface
#   ); end

#   # :inherit:
#   def apply(request : ATH::Request, configuration : Configuration(ArgType)) : Nil forall ArgType
#     raise ATH::Exceptions::BadRequest.new "Request has no body." unless (body = request.body)

#     {% begin %}
#       begin
#         {% if ArgType.instance <= ASR::Serializable %}
#           object = @serializer.deserialize ArgType, body, :json
#         {% elsif ArgType.instance <= JSON::Serializable %}
#           object = ArgType.from_json body
#         {% else %}
#           {% ArgType.raise "'#{@type}' cannot convert '#{ArgType}', as it is not serializable. '#{ArgType}' must include `JSON::Serializable` or `ASR::Serializable`." %}
#         {% end %}
#       rescue ex : JSON::ParseException | ASR::Exceptions::DeserializationException
#         raise ATH::Exceptions::BadRequest.new "Malformed JSON payload.", cause: ex
#       end

#       if object.is_a? AVD::Validatable
#         errors = @validator.validate object
#         raise AVD::Exceptions::ValidationFailed.new errors unless errors.empty?
#       end

#       request.attributes.set configuration.name, object, ArgType
#     {% end %}
#   end
# end
