# Represents an event that has access to the current request object.
module Athena::Routing::Events::RequestAware
  # Returns the current request object.
  getter request : ART::Request

  def initialize(@request : ART::Request); end
end
