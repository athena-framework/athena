# Raised when registering an `AORM::Types::Type` under a name that's already taken.
class Athena::ORM::Exception::TypesAlreadyExists < RuntimeError
  include Athena::ORM::Exception

  def initialize(name : String)
    super %(Type "#{name}" already exists.)
  end
end
