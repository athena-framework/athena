# Raised when an entity that's required doesn't exist, such as by `AORM::EntityManager#find!`.
class Athena::ORM::Exception::EntityNotFound < RuntimeError
  include Athena::ORM::Exception

  def self.from_class_name_and_identifier(class_name : String, id : Hash(String, _)) : self
    ids = id.join(", ") { |key, value| "#{key}(#{value})" }

    new "Entity of type '#{class_name}'#{" for IDs #{ids}" unless ids.empty?} was not found"
  end

  def self.no_identifier_found(class_name : String) : self
    new %(Unable to find "#{class_name}" entity identifier associated with the UnitOfWork)
  end
end
