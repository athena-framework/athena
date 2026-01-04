# Represents an event that has access to the current request object.
module Athena::HTTPKernel::Events::RequestAware
  # Returns the current request object.
  getter request : AHTTP::Request

  def initialize(@request : AHTTP::Request); end
end
