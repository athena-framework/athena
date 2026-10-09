# The join table of a many-to-many association, as configured by `AORMA::JoinTable`.
#
# See `AORM::Mapping::ManyToManyOwningSide` for its default name and columns.
class Athena::ORM::Mapping::JoinTable
  # The name of the join table.
  property name : String

  # The schema of the join table.
  property schema : String?

  # The columns referencing the entity declaring the association.
  property join_columns : Array(JoinColumn)

  # The columns referencing the target entity of the association.
  property inverse_join_columns : Array(JoinColumn)

  # Whether the name was wrapped in backticks in the mapping, so it's quoted in the generated SQL.
  property? quoted : Bool

  # :nodoc:
  def initialize(
    @name : String,
    @schema : String? = nil,
    @join_columns : Array(JoinColumn) = [] of JoinColumn,
    @inverse_join_columns : Array(JoinColumn) = [] of JoinColumn,
    @quoted : Bool = false,
  )
  end

  # Returns the fully qualified table name including schema if set.
  def qualified_name : String
    @schema ? "#{@schema}.#{@name}" : @name
  end
end
