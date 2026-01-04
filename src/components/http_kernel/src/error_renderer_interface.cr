# An `AHK::ErrorRendererInterface` converts an `::Exception` into an [AHTTP::Response](/HTTP/Response).
#
# The default implementation JSON serialize exceptions.
# However, it can be overridden to allow rendering errors differently, such as via HTML.
module Athena::HTTPKernel::ErrorRendererInterface
  # Renders the given *exception* into an [AHTTP::Response](/HTTP/Response).
  abstract def render(exception : ::Exception) : AHTTP::Response
end
