# Represents an event that has access to the current request object.
module Athena::Framework::Events::RequestAware
  # Returns the current request object.
  getter request : ATH::Request

  def initialize(@request : ATH::Request); end
end
