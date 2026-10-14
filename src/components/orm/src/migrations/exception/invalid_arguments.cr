# Raised when a query is given more types than parameters.
class Athena::ORM::Migrations::Exception::InvalidArguments < ArgumentError
  include Athena::ORM::Migrations::Exception

  def self.wrong_types_argument_count(statement : String, parameters : Int32, types : Int32) : self
    new "The number of types (#{types}) is higher than the number of passed parameters (#{parameters}) for the query \"#{statement}\"."
  end
end
