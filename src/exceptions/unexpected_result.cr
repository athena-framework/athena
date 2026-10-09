require "./orm_exception"

# Raised when a query returns a different number of results than the caller required.
class Athena::ORM::Exceptions::UnexpectedResult < Athena::ORM::Exceptions::ORMException
end
