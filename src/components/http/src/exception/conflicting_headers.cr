require "./request_exception_interface"

class Athena::HTTP::Exception::ConflictingHeaders < ArgumentError
  include Athena::HTTP::Exception::RequestExceptionInterface
end
