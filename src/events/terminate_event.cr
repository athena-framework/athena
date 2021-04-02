require "./request_aware"

# Emitted very late in the request's life-cycle, after the response has been sent.
#
# This event can be listened on to perform tasks that are not required to finish before the response is sent; such as sending emails, or other "heavy" tasks.
#
# See the [external documentation](/components/#7-terminate-event) for more information.
class Athena::Routing::Events::Terminate < AED::Event
  include Athena::Routing::Events::RequestAware

  # The response object.
  getter response : ART::Response

  def initialize(request : ART::Request, @response : ART::Response)
    super request
  end
end
