@[ADI::Register(tags: ["athena.argument_value_resolver"])]
# Handles resolving an `ADI::Service` via `ADI::ServiceContainer#resolve` with the argument's type and name.
#
# NOTE: The argument's name and type must exactly match the service that is to be resolved.
#
# ```
# @[ART::Get("")]
# def get_request_path(request_store : ART::RequestStore) : String
#   request_store.request.path
# end
# ```
struct Athena::Routing::Arguments::Resolvers::Service
  include Athena::Routing::Arguments::Resolvers::ArgumentValueResolverInterface
  include ADI::Service

  # :inherit:
  def self.priority : Int32
    -50
  end

  # :inherit:
  def supports?(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase) : Bool
    ADI.container.has? argument.name
  end

  # :inherit:
  def resolve(request : HTTP::Request, argument : ART::Arguments::ArgumentMetadataBase)
    ADI.container.resolve argument.type, argument.name
  end
end
