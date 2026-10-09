# The mapping of a property to a column, as configured by `AORMA::Column`.
#
# The field mappings of an entity are available from its class metadata, keyed by property name:
#
# ```
# field = em.class_metadata(User).field_mappings["username"]
#
# field.column_name # => "username"
# field.type        # => "string"
# ```
#
# It has the following properties:
#
# * `field_name` - The name of the property.
# * `column_name` - The name of the column, without quotes.
# * `type` - The name of the `AORM::Types::Type` used to convert the values.
# * `enum_type` - The name of the enum type of an enum property, whose values are stored as integers.
# * `id` - Whether the field is part of the identifier.
# * `not_insertable` / `not_updatable` - Whether the column is left out of `INSERT` / `UPDATE` statements.
# * `quoted` - Whether the column name was wrapped in backticks, so it's quoted in the generated SQL.
# * `length`, `precision`, `scale`, `unique`, `nullable`, `index`, `column_definition` - Describe the column's schema.
# * `generated` - Whether the database generates the column's value.
#
# TODO: There's no schema tool yet, so the properties describing the column's schema are recorded but have no effect.
#
# TODO: The `generated` property isn't supported yet; `AORMA::Column(generated: ...)` is a compile-time error.
record Athena::ORM::Mapping::Field,
  field_name : String,
  column_name : String,
  type : String,
  length : Int32? = nil,
  precision : Int32? = nil,
  scale : Int32? = nil,
  unique : Bool? = nil,
  nullable : Bool? = nil,
  not_insertable : Bool? = nil,
  not_updatable : Bool? = nil,
  enum_type : String? = nil,
  column_definition : String? = nil,
  generated : String? = nil,
  index : Bool = false,
  id : Bool? = nil,
  quoted : Bool? = nil do
  # :nodoc:
  def self.from_column_mapping(mapping : Driver::ColumnMapping) : self
    new(
      mapping.field_name,
      mapping.column_name.not_nil!,
      mapping.type.not_nil!,
      mapping.length,
      mapping.precision,
      mapping.scale,
      mapping.unique,
      mapping.nullable,
      mapping.not_insertable,
      mapping.not_updatable,
      mapping.enum_type,
      mapping.column_definition,
      mapping.generated,
      mapping.index,
      mapping.id,
      mapping.quoted,
    )
  end
end
