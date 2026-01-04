# Emitted when an exception occurs. See `AHK::Exception` for more information on how exception handling works in Athena.
#
# This event can be listened on to recover from errors or to modify the exception before it's rendered.
#
# See the [Getting Started](/getting_started/middleware#8-exception-handling) docs for more information.
class Athena::HTTPKernel::Events::Exception < ACTR::EventDispatcher::Event
  include Athena::HTTPKernel::Events::SettableResponse
  include Athena::HTTPKernel::Events::RequestAware

  # The `::Exception` associated with `self`.
  #
  # Can be replaced by an `AHK::Listeners::Error`.
  property exception : ::Exception

  def initialize(request : AHTTP::Request, @exception : ::Exception)
    super request
  end
end
