# Raised when the entity manager or unit of work is asked to do something its arguments, usually entities, don't allow.
class Athena::ORM::Exception::ORMInvalidArgument < ArgumentError
  include Athena::ORM::Exception

  def self.schedule_insert_for_managed_entity(entity : AORM::Entity) : self
    new "A managed+dirty entity #{entity} can not be scheduled for insertion."
  end

  def self.schedule_insert_for_removed_entity(entity : AORM::Entity) : self
    new "Removed entity #{entity} can not be scheduled for insertion."
  end

  def self.schedule_insert_twice(entity : AORM::Entity) : self
    new "Entity #{entity} can not be scheduled for insertion twice."
  end

  def self.entity_without_identity(class_name : String, entity : AORM::Entity) : self
    new "The given entity of type '#{class_name}' (#{entity}) has no identity/no id values set. It cannot be added to the identity map."
  end

  def self.new_entities_found_through_relationships(new_entities_with_associations : Enumerable({AORM::Mapping::Association, AORM::Entity})) : self
    messages = new_entities_with_associations.map do |(association, entity)|
      self.new_entity_found_through_relationship_message association, entity
    end

    return new messages.first if messages.size == 1

    new "Multiple non-persisted new entities were found through the given association graph:\n\n * #{messages.join "\n * "}"
  end

  def self.entity_not_managed(entity : AORM::Entity) : self
    new "Entity #{entity} is not managed. An entity is managed if its fetched from the database or registered as new through EntityManager#persist"
  end

  def self.entity_has_no_identity(entity : AORM::Entity, operation : String) : self
    new "Entity has no identity, therefore #{operation} cannot be performed. #{entity}"
  end

  def self.entity_is_removed(entity : AORM::Entity, operation : String) : self
    new "Entity is removed, therefore #{operation} cannot be performed. #{entity}"
  end

  def self.detached_entity_cannot(entity : AORM::Entity, operation : String) : self
    new "Detached entity #{entity} cannot be #{operation}"
  end

  def self.invalid_composite_identifier : self
    new "Binding an entity with a composite primary key to a query is not supported. You should split the parameter into the explicit fields and bind them separately."
  end

  def self.invalid_association(association : AORM::Mapping::Association, actual_value_type : String) : self
    new %(Expected value of type "#{association.target_entity}" for association field "#{association.source_entity}##{association.field_name}", got "#{actual_value_type}" instead.)
  end

  private def self.new_entity_found_through_relationship_message(association : AORM::Mapping::Association, entity : AORM::Entity) : String
    "A new entity was found through the relationship '#{association.source_entity}##{association.field_name}' that was not configured to cascade persist operations for entity: #{entity}. " \
    "To solve this issue: Either explicitly call EntityManager#persist on this unknown entity or configure cascade persist this association in the mapping for example @[AORMA::ManyToOne(..., cascade: [\"persist\"])]."
  end
end
