# Represents an event where an `ART::Response` can be set on `self` to handle the original `ART::Request`.
#
# WARNING: Once `#response=` is called, propagation stops; i.e. listeners with lower priority will not be executed.
module Athena::Routing::Events::SettableResponse
  # The response object, if any.
  getter response : ART::Response? = nil

  # Sets the *response* that will be returned for the current `ART::Request` being handled.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def response=(@response : ART::Response) : Nil
    self.stop_propagation
  end
end
