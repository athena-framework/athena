@[ADI::Register(name: "argument_resolver_request", tags: [{name: ATH::Arguments::Resolvers::TAG, priority: 50}])]
# Handles resolving a value for action arguments typed as `ATH::Request`.
#
# ```
# @[ARTA::Get("/")]
# def get_request_path(request : ATH::Request) : String
#   request.path
# end
# ```
struct Athena::Framework::Arguments::Resolvers::Request
  include Athena::Framework::Arguments::Resolvers::ArgumentValueResolverInterface

  # :inherit:
  def supports?(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata) : Bool
    argument.type == ATH::Request
  end

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    request
  end
end
