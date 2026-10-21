# Raised when the identifier passed to `AORM::EntityManager#find` is missing one of the fields of the entity's primary key.
#
# ```
# em.find Order, {"id" => 1}                   # raises if Order's primary key is (id, region)
# em.find Order, {"id" => 1, "region" => "eu"} # OK
# ```
class Athena::ORM::Exception::MissingIdentifierField < ::Exception
  include Athena::ORM::Exception

  def self.from_field_and_class(field_name : String, class_name : String) : self
    new "The identifier #{field_name} is missing for a query of #{class_name}"
  end
end
