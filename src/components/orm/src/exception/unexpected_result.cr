# Raised when a query returns a different number of results than the caller required.
class Athena::ORM::Exception::UnexpectedResult < RuntimeError
  include Athena::ORM::Exception
end
