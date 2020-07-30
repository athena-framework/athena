# Represents an event where an `ART::Response` can be set on `self` to handle the original `HTTP::Request`.
#
# NOTE: Once `#response=` is called, propagation stops.  Or in other words, listeners with lower priority will not be executed.
module Athena::Routing::Events::SettableResponse
  # The response object, if any.
  getter response : ART::Response? = nil

  # Sets the *response* that will be returned for the current `HTTP::Request` being handled.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def response=(@response : ART::Response) : Nil
    stop_propagation
  end
end
