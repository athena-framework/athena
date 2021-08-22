require "./param_converter"

@[ADI::Register]
class Athena::Routing::RequestBodyConverter < Athena::Routing::ParamConverter
  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface
  ); end

  # :inherit:
  def apply(request : ART::Request, configuration : Configuration(ArgType)) : Nil forall ArgType
    raise ART::Exceptions::BadRequest.new "Request has no body." unless (body = request.body)

    {% begin %}
      begin
        {% if ArgType.instance <= JSON::Serializable %}
          object = ArgType.from_json body
        {% elsif ArgType.instance <= ASR::Serializable %}
          object = @serializer.deserialize ArgType, body, :json
        {% else %}
          {% ArgType.raise "'#{@type}' cannot convert '#{ArgType}', as it is not serializable. '#{ArgType}' must include `JSON::Serializable` or `ASR::Serializable`." %}
        {% end %}
      rescue ex : JSON::ParseException | ASR::Exceptions::DeserializationException
        message = ex.message.not_nil!
        message = "Request body is empty." if message.includes? "<EOF>"
        raise ART::Exceptions::BadRequest.new message, cause: ex
      end

      if object.is_a? AVD::Validatable
        errors = @validator.validate object
        raise AVD::Exceptions::ValidationFailed.new errors unless errors.empty?
      end

      request.attributes.set configuration.name, object, ArgType
    {% end %}
  end
end
