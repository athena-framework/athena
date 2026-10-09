# A column holding a foreign key, as configured by `AORMA::JoinColumn` or `AORMA::InverseJoinColumn`.
#
# Join columns are the `AORM::Mapping::ToOneOwningSide#join_columns` of a to-one association, or the columns of the `AORM::Mapping::JoinTable` of a many-to-many association.
class Athena::ORM::Mapping::JoinColumn
  # The name of the column holding the foreign key.
  property name : String

  # The name of the column the foreign key references.
  property referenced_column_name : String

  # Whether the foreign key constraint is deferrable.
  #
  # TODO: Not set from the mapping yet, and has no effect.
  property deferrable : Bool?

  # Whether the column only allows unique values.
  property unique : Bool?

  # Whether the names were wrapped in backticks in the mapping, so they're quoted in the generated SQL.
  property quoted : Bool?

  # :nodoc:
  property field_name : String?

  # The `ON DELETE` action of the foreign key constraint, as set by the *on_delete* argument of `AORMA::JoinColumn` or `AORMA::InverseJoinColumn`.
  # Default many-to-many join columns are `"CASCADE"`, see `AORM::Mapping::Association#on_delete_cascade?`.
  property on_delete : String?

  # A custom SQL column definition.
  #
  # TODO: Not set from the mapping yet, and has no effect.
  property column_definition : String?

  # Whether the column allows `NULL`.
  property nullable : Bool?

  # :nodoc:
  def initialize(
    @name : String,
    @referenced_column_name : String,
    @deferrable : Bool? = nil,
    @unique : Bool? = nil,
    @quoted : Bool? = nil,
    @field_name : String? = nil,
    @on_delete : String? = nil,
    @column_definition : String? = nil,
    @nullable : Bool? = nil,
  )
  end
end
