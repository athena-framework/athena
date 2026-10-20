# Raised when a session is required, but the request does not have one.
class Athena::HTTP::Exception::SessionNotFound < Athena::HTTP::Exception::Logic
  include Athena::HTTP::Exception::RequestExceptionInterface
end
