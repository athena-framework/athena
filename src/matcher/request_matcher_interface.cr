# Similar to `ART::Matcher::URLMatcherInterface`, but tries to match against an `ART::Request`.
module Athena::Routing::Matcher::RequestMatcherInterface
  # Tries to match the provided *request* to its related route.
  # Returns a hash of the route's defaults and parameters resolved from the *request*.
  #
  # Raises an `ART::Exception::ResourceNotFound` if no route could be matched.
  #
  # Raises an `ART::Exception::MethodNotAllowed` if a route exists but not for the *request*'s method.
  abstract def match(request : ART::Request) : Hash(String, String?)

  # Tries to match the provided *request* to its related route.
  # Returns a hash of the route's defaults and parameters resolved from the *request*.
  #
  # Returns `nil` if no route could be matched or a route exists but not for the *request*'s method.
  abstract def match?(request : ART::Request) : Hash(String, String?)?
end
