# Represents an event where an `ATH::Response` can be set on `self` to handle the original `ATH::Request`.
#
# WARNING: Once `#response=` is called, propagation stops; i.e. listeners with lower priority will not be executed.
module Athena::Framework::Events::SettableResponse
  # The response object, if any.
  getter response : ATH::Response? = nil

  # Sets the *response* that will be returned for the current `ATH::Request` being handled.
  #
  # Propagation of `self` will stop once `#response=` is called.
  def response=(@response : ATH::Response) : Nil
    self.stop_propagation
  end
end
