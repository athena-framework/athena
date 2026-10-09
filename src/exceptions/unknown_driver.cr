require "./orm_exception"

# Raised when an `AORM::EntityManager` is created on a connection from a driver shard the ORM doesn't support.
#
# See `AORM::DriverManager` for the supported ones.
class Athena::ORM::Exceptions::UnknownDriver < Athena::ORM::Exceptions::ORMException
  def initialize(unknown_driver_name : String, known_drivers : Enumerable(String))
    super "The given driver \"#{unknown_driver_name}\" is unknown, the ORM currently supports only the following drivers: #{known_drivers.join(", ")}."
  end
end
