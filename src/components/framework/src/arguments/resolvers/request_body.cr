@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
struct Athena::Framework::Arguments::Resolvers::RequestBody
  include Athena::Framework::Arguments::Resolvers::Interface::Typed(Athena::Serializer::Serializable, JSON::Serializable)

  configuration Enable

  def initialize(
    @serializer : ASR::SerializerInterface,
    @validator : AVD::Validator::ValidatorInterface
  ); end

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    super && argument.annotation_configurations.has? Enable
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    if !(body = request.body) || body.peek.try &.empty?
      raise ATH::Exceptions::BadRequest.new "Request does not have a body."
    end

    type = argument.type

    begin
      object = if type <= ASR::Serializable
                 @serializer.deserialize type, body, :json
               elsif type <= JSON::Serializable
                 type.from_json body
               else
                 return
               end
    rescue ex : JSON::ParseException | ASR::Exceptions::DeserializationException
      raise ATH::Exceptions::BadRequest.new "Malformed JSON payload.", cause: ex
    end

    if object.is_a? AVD::Validatable
      errors = @validator.validate object
      raise AVD::Exceptions::ValidationFailed.new errors unless errors.empty?
    end

    object
  end
end
