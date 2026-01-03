# Emitted after `AHK::Events::Request` and the related `AHK::Action` has been resolved, but before it has been executed.
#
# See the [Getting Started](/getting_started/middleware#2-action-event) docs for more information.
class Athena::HTTPKernel::Events::Action < ACTR::EventDispatcher::Event
  include Athena::HTTPKernel::Events::RequestAware

  # The related `AHK::Action` that will be used to handle the current request.
  getter action : AHK::ActionBase

  def initialize(request : AHTTP::Request, @action : AHK::ActionBase)
    super request
  end
end
