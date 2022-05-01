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
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(::Enum?))
    return unless (value = request.attributes.get(argument.name, String?))

    self.resolve value, argument.name, argument.type
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    # Noop overload for non Enum types.
  end

  private def resolve(value, name : String, _enum_type : Nil.class)
    # Noop if the argument has a type of explicitly `Nil`.
  end

  private def resolve(value, name : String, _enum_type : EnumType.class) forall EnumType
    # Remove `Nil` from the union.
    enum_type = typeof(begin
      val = uninitialized EnumType
      val.nil? ? raise("") : val
    end)

    member = if (num = value.to_i128?(whitespace: false)) && (m = enum_type.from_value? num)
               m
             elsif (m = enum_type.parse? value)
               m
             end

    unless member
      raise ATH::Exceptions::BadRequest.new "Parameter '#{name}' of enum type '#{enum_type}' has no valid member for '#{value}'."
    end

    member
  end
end
