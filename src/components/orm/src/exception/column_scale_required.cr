require "./invalid_column_type"

# Raised when a decimal column's scale isn't set.
class Athena::ORM::Exception::ColumnScaleRequired < Athena::ORM::Exception::InvalidColumnType
  def initialize
    super "Column scale is not specified"
  end
end
