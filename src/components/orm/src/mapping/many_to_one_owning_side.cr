require "./to_one_owning_side"
require "./many_to_one"

# Mapping for ManyToOne associations.
# The "many" side always owns the FK column, so this is always the owning side of the relationship.
class Athena::ORM::Mapping::ManyToOneOwningSide < Athena::ORM::Mapping::ToOneOwningSide
  include Athena::ORM::Mapping::ManyToOne
end
