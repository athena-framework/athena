# Raised when a closed `AORM::EntityManager` is used.
class Athena::ORM::Exception::EntityManagerClosed < RuntimeError
  include Athena::ORM::Exception

  def self.create : self
    new "The EntityManager is closed."
  end
end
