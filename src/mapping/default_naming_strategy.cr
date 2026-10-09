require "./naming_strategy_interface"

# The naming strategy used for every entity.
#
# It derives names from the unqualified class names and property names:
#
# * A column is named after its property, e.g. `created_at`.
# * A to-one join column is named `<property>_id`, and references the target's `id` column.
# * A many-to-many join table is named `<source>_<target>` using the underscored class names, e.g. `user_group` for `User#groups`.
# * The join table's columns are named `<class>_id` using the underscored class names, e.g. `user_id` and `group_id`, and reference the `id` columns.
#
# The table of an entity defaults to its underscored class name, e.g. `user_profile` for `App::UserProfile`.
#
# ```
# @[AORMA::Entity]
# class User < AORM::Entity
#   # Mapped to the `display_name` column of the `user` table.
#   @[AORMA::Column]
#   property! display_name : String
#
#   # Mapped to the `avatar_id` join column, referencing `avatar.id`.
#   @[AORMA::OneToOne]
#   property avatar : Avatar? = nil
#
#   # Mapped through the `user_group` join table, with the `user_id` and `group_id` columns.
#   @[AORMA::ManyToMany]
#   property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
#
#   # ...
# end
# ```
struct Athena::ORM::Mapping::DefaultNamingStrategy
  include Athena::ORM::Mapping::NamingStrategyInterface

  def property_to_column_name(property_name : String, entity_class : AORM::Entity.class) : String
    property_name
  end

  def reference_column_name : String
    "id"
  end

  def join_column_name(property_name : String, entity_class : AORM::Entity.class) : String
    "#{property_name}_#{self.reference_column_name}"
  end

  def join_table_name(source_entity : String, target_entity : String, property_name : String?) : String
    "#{source_entity.underscore}_#{target_entity.underscore}"
  end

  def join_key_column_name(entity_name : String, referenced_column_name : String?) : String
    suffix = referenced_column_name || self.reference_column_name
    "#{entity_name.underscore}_#{suffix}"
  end
end
