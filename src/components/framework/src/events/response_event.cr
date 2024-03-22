require "./request_aware"

# Emitted after the route's action has been executed, but before the response has been returned to the client.
#
# This event can be listened on to modify the response object further before it is returned;
# such as adding headers/cookies, compressing the response, etc.
#
# See the [Getting Started](/getting_started/middleware#5-response-event) docs for more information.
class Athena::Framework::Events::Response < AED::Event
  include Athena::Framework::Events::RequestAware

  # The response object.
  property response : ATH::Response

  def initialize(request : ATH::Request, @response : ATH::Response)
    super request
  end
end
