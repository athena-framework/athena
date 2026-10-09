# Determines the default names of the columns, join columns, and join tables of mapped entities.
#
# A name given explicitly in the mapping, such as `AORMA::Column(name: ...)` or `AORMA::JoinTable(name: ...)`, always takes precedence over the naming strategy.
# See `AORM::Mapping::DefaultNamingStrategy` for the names it produces.
#
# TODO: A custom naming strategy can't be configured yet; every entity uses `AORM::Mapping::DefaultNamingStrategy`.
module Athena::ORM::Mapping::NamingStrategyInterface
  # abstract def class_to_table_name(entity_class : AORM::Entity.class) : String

  # Returns the column name for the property named *property_name* of *entity_class*.
  abstract def property_to_column_name(property_name : String, entity_class : AORM::Entity.class) : String

  # abstract def embedded_field_to_column_name(property_name : String, embedded_column_name : String, entity_class : AORM::Entity.class, embedded_entity_class : AORM::Entity.class) : String

  # Returns the name of the column join columns reference by default.
  abstract def reference_column_name : String

  # Returns the name of the join table of a many-to-many association from *source_entity* to *target_entity*, given their unqualified class names.
  abstract def join_table_name(source_entity : String, target_entity : String, property_name : String?) : String

  # Returns the join column name of the to-one association property named *property_name* of *entity_class*.
  abstract def join_column_name(property_name : String, entity_class : AORM::Entity.class) : String

  # Returns the name of a join table column referencing the entity with the unqualified class name *entity_name*.
  abstract def join_key_column_name(entity_name : String, referenced_column_name : String?) : String
end
