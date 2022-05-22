@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
struct Athena::Framework::Arguments::Resolvers::Time
  include Athena::Framework::Arguments::Resolvers::Interface::Typed(::Time)

  configuration Format, format : String? = nil, location : ::Time::Location = ::Time::Location::UTC

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    super && (request.attributes.has?(argument.name, String) || request.attributes.has?(argument.name, ::Time))
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    value = request.attributes.get argument.name, String | ::Time

    return value if value.is_a? ::Time

    if !(configuration = argument.annotation_configurations[Format]?) || !(format = configuration.format)
      return ::Time.parse_rfc3339(value)
    end

    ::Time.parse value, format, configuration.location
  end
end
