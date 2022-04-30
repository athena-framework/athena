@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
struct Athena::Framework::Arguments::Resolvers::Enum
  include Athena::Framework::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(::Enum?)) : Bool
    request.attributes.has? argument.name
  end

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    false
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(EnumType)) forall EnumType
    {% if EnumType <= ::Enum %}
      return unless (value = request.attributes.get(argument.name, String?))

      enum_type = {{ EnumType.nilable? ? EnumType.union_types.reject(&.nilable?).first : EnumType }}

      member = if (num = value.to_i64?(whitespace: false)) && (m = enum_type.from_value? num)
                 m
               elsif (m = enum_type.parse? value)
                 m
               end

      unless member
        raise ATH::Exceptions::BadRequest.new "Parameter '#{argument.name}' of enum type '#{EnumType}' has no valid member for '#{value}'."
      end

      member
    {% end %}
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    # Noop overload for non Enum types.
  end
end
