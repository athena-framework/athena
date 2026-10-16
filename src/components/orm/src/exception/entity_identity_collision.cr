# Raised when an entity is added to the identity map, but another entity is already there for the same identifier.
class Athena::ORM::Exception::EntityIdentityCollision < RuntimeError
  include Athena::ORM::Exception

  def self.create(existing_entity : AORM::Entity, new_entity : AORM::Entity, id_hash : String) : self
    new <<-MESSAGE
      While adding an entity of class #{new_entity.class} with an ID hash of "#{id_hash}" to the identity map,
      another object of class #{existing_entity.class} was already present for the same ID. This exception
      is a safeguard against an internal inconsistency - IDs should uniquely map to
      entity object instances. This problem may occur if:

      - you use application-provided IDs and reuse ID values;
      - database-provided IDs are reassigned after truncating the database without
      clearing the EntityManager.

      Otherwise, it might be an ORM-internal inconsistency, please report it.
      MESSAGE
  end
end
