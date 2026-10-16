# Raised when committing or rolling back without an active transaction.
class Athena::ORM::Exception::NoActiveTransaction < RuntimeError
  include Athena::ORM::Exception

  def initialize
    super "There is no active transaction."
  end
end
