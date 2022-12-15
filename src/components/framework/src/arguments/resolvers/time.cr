@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
struct Athena::Framework::Arguments::Resolvers::Time
  include Athena::Framework::Arguments::Resolvers::Interface

  configuration Format, format : String? = nil, location : ::Time::Location = ::Time::Location::UTC

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    if !argument.instance_of? ::Time
      return
    end

    if value = request.attributes.get? argument.name, ::Time?
      return value
    end

    return unless (value = request.attributes.get? argument.name, String?)

    if !(configuration = argument.annotation_configurations[Format]?) || !(format = configuration.format)
      return ::Time.parse_rfc3339(value)
    end

    ::Time.parse value, format, configuration.location
  rescue ex : ::Time::Format::Error
    raise ATH::Exceptions::BadRequest.new "Invalid date(time) for parameter '#{argument.name}'."
  end
end
