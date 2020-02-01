require "./request_aware"
require "./settable_response"

# Emitted after the route's action has been executed, but only if it does _NOT_ return an `ART::Response`.
#
# This event can be listened on to handle converting a non `ART::Response` into an `ART::Response`.
#
# See `ART::Listeners::View`.
class Athena::Routing::Events::View < AED::Event
  include Athena::Routing::Events::SettableResponse
  include Athena::Routing::Events::RequestAware

  getter view : ViewBase

  def initialize(request : HTTP::Request, @view : ViewBase)
    super request
  end
end
