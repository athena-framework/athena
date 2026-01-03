# Emitted very early in the request's life-cycle; before the corresponding `AHK::Action` (if any) has been resolved.
#
# This event can be listened on in order to:
#
# * Add information to the request, via its [AHTTP::Request#attributes](/HTTP/Request/#Athena::HTTP::Request#attributes)
# * Return a response immediately if there is enough information available
#
# NOTE: If your listener logic requires that the the corresponding `AHK::Action` has been resolved, use `AHK::Events::Action` instead.
#
# See the [Getting Started](/getting_started/middleware#1-request-event) docs for more information.
class Athena::HTTPKernel::Events::Request < ACTR::EventDispatcher::Event
  include Athena::HTTPKernel::Events::SettableResponse
  include Athena::HTTPKernel::Events::RequestAware
end
