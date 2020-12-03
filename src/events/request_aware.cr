# Represents an event that has access to the current request object.
module Athena::Routing::Events::RequestAware
  # Returns the current request object.
  getter request : HTTP::Request

  def initialize(@request : HTTP::Request); end
end
