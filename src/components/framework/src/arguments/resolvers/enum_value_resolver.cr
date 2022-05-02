@[ADI::Register(tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 105}])]
# Handles resolving an [Enum](https://crystal-lang.org/api/Enum.html) member from a value that is stored in the request's `ATH::Request#attributes`.
# This resolver supports both numeric and string based parsing, returning a proper error response if the provided value does not map to any valid member.
#
# ```
# require "athena"
#
# enum Color
#   Red
#   Blue
#   Green
# end
#
# class ExampleController < ATH::Controller
#   @[ARTA::Get("/numeric/{color}")]
#   def get_color_numeric(color : Color) : Color
#     color
#   end
#
#   @[ARTA::Get("/string/{color}")]
#   def get_color_string(color : Color) : Color
#     color
#   end
# end
#
# ATH.run
#
# # GET /numeric/1 # => "blue"
# # GET /string/red # => "red"
# ```
#
# TIP: Checkout `ART::Requirement::Enum` for an easy way to restrict routing to an enum's members, or a subset of them.
# WARNING: Only non-nilable Enum types are supported.
struct Athena::Framework::Arguments::Resolvers::Enum
  include Athena::Framework::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(::Enum)) : Bool
    request.attributes.has? argument.name
  end

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    false
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata(::Enum))
    return unless (value = request.attributes.get(argument.name, String?))

    member = if (num = value.to_i128?(whitespace: false)) && (m = argument.type.from_value? num)
               m
             elsif (m = argument.type.parse? value)
               m
             end

    unless member
      raise ATH::Exceptions::BadRequest.new "Parameter '#{argument.name}' of enum type '#{argument.type}' has no valid member for '#{value}'."
    end

    member
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    # Noop overload for non Enum types.
  end
end
