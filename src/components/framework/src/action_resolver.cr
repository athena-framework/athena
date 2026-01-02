# The route matched matched via `ATH::Listeners::Routing` needs to be resolved to the `ATH::Action` instance that actually represents the action (controller) of the request.
module Athena::Framework::ActionResolverInterface
  # Resolves the `ATH::Action` instance that should handle the provided *request*.
  abstract def resolve(request : AHTTP::Request) : ATH::ActionBase?
end

@[ADI::Register]
@[ADI::AsAlias]
# Default `ATH::ActionResolverInterface` implementation that looks for an `_action` key within [AHTTP::Request#attributes](/HTTP/Request/#Athena::HTTP::Request#attributes).
class Athena::Framework::ActionResolver
  include Athena::Framework::ActionResolverInterface

  # :inherit:
  def resolve(request : AHTTP::Request) : ATH::ActionBase?
    request.attributes.get? "_action", ATH::ActionBase
  end
end
