@[ADI::Register(tags: [{name: ART::Arguments::Resolvers::TAG, priority: -100}])]
# Handles resolving an argument's default value if no other value was able to be resolved.
#
# ```
# @[ART::Get("")]
# @[ART::QueryParam("query_param")]
# def get_query_param(query_param : Int32 = 123) : Int32
#   # `query_param` would be `123` if the request does not include a query parameter named `query_param`.
#   query_param
# end
# ```
struct Athena::Routing::Arguments::Resolvers::DefaultValue
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
    argument.has_default? || (argument.type != Nil && argument.nillable?)
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata)
    argument.has_default? ? argument.default : nil
  end
end
