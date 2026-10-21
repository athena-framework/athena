# Raised when a method requires the connection to have a database selected, but it has none.
class Athena::ORM::Exception::DatabaseRequired < RuntimeError
  include Athena::ORM::Exception

  def initialize(method_name : String)
    super "A database is required for the method: #{method_name}."
  end
end
