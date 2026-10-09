require "./to_one_owning_side"

# Mapping for the owning side of a OneToOne association, which holds the foreign key column.
class Athena::ORM::Mapping::OneToOneOwningSide < Athena::ORM::Mapping::ToOneOwningSide
  include Athena::ORM::Mapping::OneToOne
end
