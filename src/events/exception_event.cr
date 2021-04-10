require "./request_event"
require "./settable_response"

# Emitted when an exception occurs.  See `ART::Exceptions` for more information on how exception handling works in Athena.
#
# This event can be listened on to recover from errors or to modify the exception before it's rendered.
#
# See the [external documentation](/components/#8-exception-handling) for more information.
class Athena::Routing::Events::Exception < AED::Event
  include Athena::Routing::Events::SettableResponse
  include Athena::Routing::Events::RequestAware

  # The `::Exception` associated with `self`.
  #
  # Can be replaced by an `ART::Listeners::Error`.
  property exception : ::Exception

  def initialize(request : ART::Request, @exception : ::Exception)
    super request
  end
end
