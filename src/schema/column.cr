# Describes a database column, as passed to `AORM::Types::Type#sql_declaration` to build the SQL declaring it.
#
# TODO: Nothing in the ORM generates schema yet, so the ORM itself never builds columns or calls `AORM::Types::Type#sql_declaration`.
class Athena::ORM::Schema::Column
  # Returns the name of the column.
  getter name : String

  # Returns the type of the column's values.
  getter type : Types::Type

  # The maximum length of a string or binary column.
  property length : Int32? = nil

  # The total number of digits of a decimal column.
  property precision : Int32? = nil

  # The number of digits to the right of the decimal point of a decimal column.
  property scale : Int32? = nil

  # Whether a string or binary column has a fixed length.
  property? fixed : Bool = false

  # Whether the database generates the column's value, e.g. an identity column.
  property? auto_increment : Bool = false

  # Whether a numeric column is unsigned, on platforms supporting it.
  property? unsigned : Bool = false

  # Creates a column named *name*, holding values of *type*.
  def initialize(
    @name : String,
    @type : Types::Type,
  ); end
end
