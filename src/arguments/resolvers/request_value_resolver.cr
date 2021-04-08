@[ADI::Register(name: "argument_resolver_request", tags: [{name: ART::Arguments::Resolvers::TAG, priority: 50}])]
# Handles resolving a value for action arguments typed as `ART::Request`.
#
# ```
# @[ARTA::Get("/")]
# def get_request_path(request : ART::Request) : String
#   request.path
# end
# ```
struct Athena::Routing::Arguments::Resolvers::Request
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ART::Request, argument : ART::Arguments::ArgumentMetadata) : Bool
    argument.type <= ART::Request
  end

  # :inherit:
  def resolve(request : ART::Request, argument : ART::Arguments::ArgumentMetadata)
    request
  end
end
