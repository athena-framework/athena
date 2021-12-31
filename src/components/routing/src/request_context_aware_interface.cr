# Represents a type that has access to the current `ART::RequestContext`.
module Athena::Routing::RequestContextAwareInterface
  # Returns the request context.
  abstract def context : ART::RequestContext

  # Sets the request context.
  abstract def context=(context : ART::RequestContext)
end
