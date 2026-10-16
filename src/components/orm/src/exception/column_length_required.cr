require "./invalid_column_type"

# Raised when a platform requires a column's length to declare its type, but it isn't set.
class Athena::ORM::Exception::ColumnLengthRequired < Athena::ORM::Exception::InvalidColumnType
  def initialize(platform : AORM::Platforms::Platform, type : String)
    super "#{platform.class} requires the length of a #{type} column to be specified"
  end
end
