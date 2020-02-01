require "./request_aware"
require "./settable_response"

# Emitted very early in the request's life-cycle; before the corresponding `ART::Route` (if any) has been resolved.
#
# This event can be listened on to add information to the request, or return a response before even triggering the router; `ART::Listeners::CORS` is an example of this.
class Athena::Routing::Events::Request < AED::Event
  include Athena::Routing::Events::SettableResponse
  include Athena::Routing::Events::RequestAware
end
