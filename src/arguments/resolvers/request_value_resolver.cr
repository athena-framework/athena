@[ADI::Register(name: "argument_resolver_request", tags: [{name: ART::Arguments::Resolvers::TAG, priority: 50}])]
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

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
    argument.type <= HTTP::Request
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadata)
    request
  end
end
