require "./request_aware"
require "./settable_response"

# Emitted very early in the request's life-cycle; before the corresponding `ATH::Action` (if any) has been resolved.
#
# This event can be listened on in order to:
#
# * Add information to the request, via its `ATH::Request#attributes`
# * Return a response immediately if there is enough information available; `ATH::Listeners::CORS` is an example of this
#
# NOTE: If your listener logic requires that the the corresponding `ATH::Action` has been resolved, use `ATH::Events::Action` instead.
#
# See the [external documentation](/architecture/#1-request-event) for more information.
class Athena::Framework::Events::Request < AED::Event
  include Athena::Framework::Events::SettableResponse
  include Athena::Framework::Events::RequestAware
end
