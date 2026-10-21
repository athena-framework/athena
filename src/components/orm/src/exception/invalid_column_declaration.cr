require "./invalid_column_type"

# Raised when the SQL declaring a column can't be built, with the `InvalidColumnType` saying why as its cause.
class Athena::ORM::Exception::InvalidColumnDeclaration < ::Exception
  include Athena::ORM::Exception

  def self.from_invalid_column_type(column_name : String, cause : AORM::Exception::InvalidColumnType) : self
    new %(Column "#{column_name}" has invalid type), cause
  end
end
