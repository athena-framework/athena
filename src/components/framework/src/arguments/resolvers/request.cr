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
  include Athena::Framework::Arguments::Resolvers::Interface

  # :inherit:
  def resolve(request : ATH::Request, argument : ATH::Arguments::ArgumentMetadata)
    return unless argument.instance_of? ::ATH::Request

    request
  end
end
