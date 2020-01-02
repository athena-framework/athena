@[Athena::DI::Register]
# Stores the current `HTTP::Request` object.
class Athena::Routing::RequestStore
  include Athena::DI::Service

  # Returns the currently executing request.  The request may be `nil`
  # if the request is finished, or `self` was injected into
  # something that doesn't directly execute within the context
  # of a request.  Use the nilable getter `#request?`, if that is a possibility.
  property! request : HTTP::Request
end
