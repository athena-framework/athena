@[ADI::Register(name: "argument_resolver_default", tags: [{name: ATH::Arguments::Resolvers::TAG, priority: -100}])]
# Handles resolving an argument's default value if no other value was able to be resolved.
#
# ```
# @[ATHA::Get("/")]
# @[ATHA::QueryParam("query_param")]
# def get_query_param(query_param : Int32 = 123) : Int32
#   # `query_param` would be `123` if the request does not include a query parameter named `query_param`.
#   query_param
# end
# ```
struct Athena::Framework::Arguments::Resolvers::DefaultValue
  include Athena::Framework::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    argument.has_default? || (argument.type != Nil && argument.nilable?)
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    argument.has_default? ? argument.default : nil
  end
end
