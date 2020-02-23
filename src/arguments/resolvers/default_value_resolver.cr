@[ADI::Register(tags: ["athena.argument_value_resolver"])]
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
  include ADI::Service

  # :inherit:
  def self.priority : Int32
    -100
  end

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase) : Bool
    argument.has_default? || (argument.type != Nil && argument.nillable?)
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase)
    argument.has_default? ? argument.default : nil
  end
end
