# Raised when an entity whose identifier is assigned by the application is persisted without one, see `AORMA::GeneratedValue`.
class Athena::ORM::Exception::EntityMissingAssignedId < ::Exception
  include Athena::ORM::Exception

  def self.for_field(entity : AORM::Entity, field : String) : self
    new "Entity of type #{entity.class} is missing an assigned ID for field '#{field}'. " \
        "The identifier generation strategy for this entity requires the ID field to be populated before EntityManager#persist is called. " \
        "If you want automatically generated identifiers instead you need to adjust the metadata mapping accordingly."
  end
end
