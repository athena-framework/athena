require "./request_aware"
require "./settable_response"

# Emitted very early in the request's life-cycle; before the corresponding `ART::Action` (if any) has been resolved.
#
# This event can be listened on in order to:
#
# * Add information to the request, via its `ART::Request#attributes`
# * Return a response immediately if there is enough information available; `ART::Listeners::CORS` is an example of this
#
# !!!note
#     If your listener logic requires that the the corresponding `ART::Action` has been resolved, use `ART::Events::Action` instead.
#
# See the [external documentation](/components/#1-request-event) for more information.
class Athena::Routing::Events::Request < AED::Event
  include Athena::Routing::Events::SettableResponse
  include Athena::Routing::Events::RequestAware
end
