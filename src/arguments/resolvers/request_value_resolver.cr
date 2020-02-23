@[ADI::Register(tags: ["athena.argument_value_resolver"])]
# Handles resolving a value for action arguments type as `HTTP::Request`.
#
# ```
# @[ART::Get("")]
# def get_request_path(request : HTTP::Request) : String
#   request.path
# end
# ```
struct Athena::Routing::Arguments::Resolvers::Request
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  include ADI::Service

  # :inherit:
  def self.priority : Int32
    50
  end

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase) : Bool
    argument.type <= HTTP::Request
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase)
    request
  end
end
