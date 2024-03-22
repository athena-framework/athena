require "./request_event"
require "./settable_response"

# Emitted when an exception occurs. See `ATH::Exceptions` for more information on how exception handling works in Athena.
#
# This event can be listened on to recover from errors or to modify the exception before it's rendered.
#
# See the [Getting Started](/getting_started/middleware#8-exception-handling) docs for more information.
class Athena::Framework::Events::Exception < AED::Event
  include Athena::Framework::Events::SettableResponse
  include Athena::Framework::Events::RequestAware

  # The `::Exception` associated with `self`.
  #
  # Can be replaced by an `ATH::Listeners::Error`.
  property exception : ::Exception

  def initialize(request : ATH::Request, @exception : ::Exception)
    super request
  end
end
