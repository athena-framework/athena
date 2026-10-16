# Raised when overriding an `AORM::Types::Type` that isn't registered.
class Athena::ORM::Exception::TypeNotFound < RuntimeError
  include Athena::ORM::Exception

  def initialize(name : String)
    super %(Type to be overwritten "#{name}" does not exist.)
  end
end
