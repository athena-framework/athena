require "./invalid_column_type"

# Raised when a decimal column's precision isn't set.
class Athena::ORM::Exception::ColumnPrecisionRequired < Athena::ORM::Exception::InvalidColumnType
  def initialize
    super "Column precision is not specified"
  end
end
