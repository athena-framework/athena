# Represents an event where an `AHTTP::Response` can be set on `self` to handle the original `AHTTP::Request`.
#
# WARNING: Once `#response=` is called, propagation stops; i.e. listeners with lower priority will not be executed.
module Athena::Framework::Events::SettableResponse
  # The response object, if any.
  getter response : AHTTP::Response? = nil

  # Sets the *response* that will be returned for the current `AHTTP::Request` being handled.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def response=(@response : AHTTP::Response) : Nil
    self.stop_propagation
  end
end
