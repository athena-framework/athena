require "./request_event"

# Emitted when an exception occurs.  See `ART::Exceptions` for more information on how exception handling works in Athena.
#
# This event can be listened on to execute some code when an exception occurs; such as for logging/analytics etc.
#
# TODO: Refactor this to be similar to `ART::Events::Request` to support error renderers.
class Athena::Routing::Events::Exception < AED::Event
  include Athena::Routing::Events::RequestAware

  # The response object.
  getter response : ART::Response? = nil

  property exception : ::Exception

  def initialize(request : HTTP::Request, @exception : ::Exception)
    super request
  end

  def response=(@response : ART::Response) : Nil
    stop_propagation
  end
end
