# Raised when query results can't be hydrated into entities, see `AORM::NativeQuery`.
class Athena::ORM::Exception::Hydration < RuntimeError
  include Athena::ORM::Exception

  def self.parent_object_of_relation_not_found(alias_name : String, parent_alias : String) : self
    new "The parent object of entity result with alias '#{alias_name}' was not found. The parent alias is '#{parent_alias}'."
  end
end
