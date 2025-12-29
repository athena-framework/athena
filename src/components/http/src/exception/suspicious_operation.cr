class Athena::HTTP::Exception::SuspiciousOperation < ArgumentError
  include Athena::HTTP::Exception::RequestExceptionInterface
end
