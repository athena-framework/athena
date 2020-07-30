require "./request_aware"

# Emitted after the route's action has been executed, but before the response has been returned to the client.
#
# This event can be listened on to modify the response object further before it is returned;
# such as adding headers/cookies, compressing the response, etc.
class Athena::Routing::Events::Response < AED::Event
  include Athena::Routing::Events::RequestAware

  # The response object.
  property response : ART::Response

  def initialize(request : HTTP::Request, @response : ART::Response)
    super request
  end
end
