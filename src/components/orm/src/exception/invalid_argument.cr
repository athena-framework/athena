# Raised when a method is given an argument it can't use.
class Athena::ORM::Exception::InvalidArgument < ArgumentError
  include Athena::ORM::Exception
end
