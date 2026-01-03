# Default `AHK::ActionResolverInterface` implementation that looks for an `_action` key
# within [AHTTP::Request#attributes](/HTTP/Request/#Athena::HTTP::Request#attributes).
class Athena::HTTPKernel::ActionResolver
  include Athena::HTTPKernel::ActionResolverInterface

  # :inherit:
  def resolve(request : AHTTP::Request) : AHK::ActionBase?
    request.attributes.get? "_action", AHK::ActionBase
  end
end
