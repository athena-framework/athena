# Resolves the `AHK::ActionBase` for a given request.
#
# The route matched via `AHK::Listeners::Routing` (or equivalent) needs to be resolved to the `AHK::ActionBase` instance that actually represents the action (controller) of the request.
module Athena::HTTPKernel::ActionResolverInterface
  # Resolves the `AHK::ActionBase` instance that should handle the provided *request*.
  abstract def resolve(request : AHTTP::Request) : AHK::ActionBase?
end
