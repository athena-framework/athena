require "./orm_exception"

# Raised when the identifier passed to `AORM::EntityManager#find` doesn't match the entity's primary key.
#
# That is, when a `Hash` identifier is missing one of the primary key's fields, or a single value is passed for an entity with a composite primary key.
#
# ```
# em.find Order, {"id" => 1}                   # raises if Order's primary key is (id, region)
# em.find Order, 1                             # raises too
# em.find Order, {"id" => 1, "region" => "eu"} # OK
# ```
class Athena::ORM::Exceptions::MissingIdentifierField < Athena::ORM::Exceptions::ORMException
  def initialize(entity_class : AORM::Entity.class, missing : Enumerable(String))
    super "Missing identifier field(s) for '#{entity_class}': #{missing.join(", ")}"
  end

  def initialize(entity_class : AORM::Entity.class, message : String)
    super "Identifier mismatch for '#{entity_class}': #{message}"
  end
end
