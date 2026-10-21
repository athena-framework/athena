# Raised when a value can't be converted between its Crystal and database representations, see `AORM::Types::Type`.
class Athena::ORM::Exception::Conversion < RuntimeError
  include Athena::ORM::Exception
end
