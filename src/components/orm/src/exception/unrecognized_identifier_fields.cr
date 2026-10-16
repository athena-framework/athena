# Raised when the identifier passed to `AORM::EntityManager#find` has fields that aren't part of the entity's primary key.
#
# ```
# em.find User, {"id" => 1, "name" => "George"} # raises, since User's primary key is only (id)
# ```
class Athena::ORM::Exception::UnrecognizedIdentifierFields < ::Exception
  include Athena::ORM::Exception

  def self.from_class_and_field_names(class_name : String, field_names : Enumerable(String)) : self
    new %(Unrecognized identifier fields: "#{field_names.join "', '"}" are not present on class "#{class_name}".)
  end
end
