@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
struct Athena::Framework::Arguments::Resolvers::RequestBody
  include Athena::Framework::Arguments::Resolvers::Interface::Typed(Athena::Serializer::Serializable, JSON::Serializable)

  configuration Enable

  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface
  ); end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(T)) : T? forall T
    return unless argument.annotation_configurations.has? Enable

    if !(body = request.body) || body.peek.try &.empty?
      raise ATH::Exceptions::BadRequest.new "Request does not have a body."
    end

    object = nil

    begin
      {% begin %}
        {% if T.instance <= ASR::Serializable %}
          object = @serializer.deserialize T, body, :json
        {% elsif T.instance <= JSON::Serializable %}
          object = T.from_json body
        {% else %}
          return
        {% end %}
      {% end %}
    rescue ex : JSON::ParseException | ASR::Exceptions::DeserializationException
      raise ATH::Exceptions::BadRequest.new "Malformed JSON payload.", cause: ex
    end

    if object.is_a? AVD::Validatable
      errors = @validator.validate object
      raise AVD::Exceptions::ValidationFailed.new errors unless errors.empty?
    end

    object.as T
  end
end
