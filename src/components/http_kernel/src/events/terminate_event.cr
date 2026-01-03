# Emitted very late in the request's life-cycle, after the response has been sent.
#
# This event can be listened on to perform tasks that are not required to finish before the response is sent; such as sending emails, or other "heavy" tasks.
#
# See the [Getting Started](/getting_started/middleware#7-terminate-event) docs for more information.
class Athena::HTTPKernel::Events::Terminate < ACTR::EventDispatcher::Event
  include Athena::HTTPKernel::Events::RequestAware

  # The response object.
  getter response : AHTTP::Response

  def initialize(request : AHTTP::Request, @response : AHTTP::Response)
    super request
  end
end
