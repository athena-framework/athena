# Raised when the mapping of an entity is invalid, see `AORM::Mapping::Class`.
class Athena::ORM::Exception::Mapping < RuntimeError
  include Athena::ORM::Exception

  def self.single_id_not_allowed_on_composite_primary_key(entity : String) : self
    new "Single id is not allowed on composite primary key in entity #{entity}"
  end

  def self.no_id_defined(entity : String) : self
    new "No ID defined for entity #{entity}"
  end

  def self.missing_field_name(entity : String) : self
    new "The field or association mapping misses the 'field_name' attribute in entity '#{entity}'."
  end

  def self.missing_target_entity(field_name : String) : self
    new "The association mapping '#{field_name}' misses the 'target_entity' attribute."
  end

  def self.duplicate_column_name(class_name : String, column_name : String) : self
    new "Duplicate definition of column '#{column_name}' on entity '#{class_name}' in a field or discriminator column mapping."
  end

  def self.duplicate_field_mapping(entity : String, field_name : String) : self
    new %(Property "#{field_name}" in "#{entity}" was already declared, but it must be declared only once)
  end

  def self.illegal_orphan_removal(class_name : String, field : String) : self
    new "Orphan removal is only allowed on one-to-one and one-to-many associations, but #{class_name}##{field} is not."
  end

  def self.illegal_to_many_identifier_association(class_name : String, field : String) : self
    new "Many-to-many or one-to-many associations are not allowed to be identifier in '#{class_name}##{field}'."
  end

  def self.illegal_orphan_removal_on_identifier_association(class_name : String, field : String) : self
    new "The orphan removal option is not allowed on an association that is part of the identifier in '#{class_name}##{field}'."
  end

  def self.cannot_map_composite_primary_key_entities_as_foreign_id(class_name : AORM::Entity.class | String | Nil, target_entity : String, target_field : String) : self
    new "It is not possible to map entity '#{class_name}' with a composite primary key as part of the primary key of another entity '#{target_entity}##{target_field}'."
  end

  def self.invalid_cascade_option(cascades : Enumerable(String), class_name : String, property_name : String) : self
    new "You have specified invalid cascade options for #{class_name}##{property_name}: #{cascades.join(", ") { |cascade| "'#{cascade}'" }}; available options: 'remove', 'persist', 'refresh', and 'detach'"
  end

  def self.join_column_not_allowed_on_one_to_one_inverse_side(class_name : String, field_name : String) : self
    new "#{class_name}##{field_name} is a OneToOne inverse side, which does not allow join columns."
  end

  def self.illegal_inverse_identifier_association(class_name : String, field : String) : self
    new "An inverse association is not allowed to be identifier in '#{class_name}##{field}'."
  end

  def self.invalid_association_type(entity_name : String, field_name : String, type : String) : self
    new %(The association "#{entity_name}##{field_name}" must be of type "one_to_one", "one_to_many", "many_to_many" or "many_to_one", "#{type}" given.)
  end

  def self.one_to_many_requires_mapped_by(entity_name : String, field_name : String) : self
    new "OneToMany mapping on entity '#{entity_name}' field '#{field_name}' requires the 'mapped_by' attribute."
  end

  def self.cannot_set_nullable_on_to_one_identifier_join_columns(class_name : String, field_name : String) : self
    new %(Cannot specify the "nullable" attribute for join columns in to-one associations (#{class_name}##{field_name}) that are part of the identifier)
  end

  def self.illegal_lifecycle_callback_on_embedded_class(event : AORM::Events::EventArgs.class, class_name : String) : self
    new <<-MESSAGE
      Context: Attempt to register lifecycle callback "#{event}" on embedded class "#{class_name}".
      Problem: Registering lifecycle callbacks on embedded classes is not allowed.
      MESSAGE
  end

  def self.invalid_attribute_on_embeddable(entity_name : String, attribute_name : String) : self
    new %(Attribute "#{attribute_name}" on embeddable "#{entity_name}" is not allowed.)
  end

  def self.missing_required_option(field : String, expected_option : String, hint : String = "") : self
    message = "The mapping of field '#{field}' is invalid: The option '#{expected_option}' is required."
    message += " (Hint: #{hint})" unless hint.empty?

    new message
  end

  def self.join_column_must_point_to_mapped_field(class_name : String, join_column : String) : self
    new "The column #{join_column} must be mapped to a field in class #{class_name} since it is referenced by a join column of another class."
  end

  def self.integer_type_required_for_enum(class_name : String, field_name : String, type : String) : self
    new "Enum field '#{field_name}' on #{class_name} must be mapped to an integer type, got '#{type}'"
  end

  def self.proxy_not_allowed_on_to_one_inverse_side(class_name : String, field_name : String) : self
    new "AORM::Proxy(T) is only valid on owning-side ToOne fields; field '#{field_name}' on '#{class_name}' is the inverse side"
  end

  def self.field_type_mismatch(class_name : String, field_name : String, value_type : String) : self
    new "Type mismatch for '#{field_name}' on #{class_name}: got #{value_type}"
  end
end
