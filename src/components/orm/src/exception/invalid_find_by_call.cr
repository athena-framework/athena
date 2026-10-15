# Raised when an entity is searched for by the inverse side of an association, see `AORM::EntityRepository#find_by`.
class Athena::ORM::Exception::InvalidFindByCall < ::Exception
  include Athena::ORM::Exception

  def self.from_inverse_side_usage(entity_name : String, association_field_name : String) : self
    new "You cannot search for the association field '#{entity_name}##{association_field_name}', because it is the inverse side of an association. Find methods only work on owning side associations."
  end
end
