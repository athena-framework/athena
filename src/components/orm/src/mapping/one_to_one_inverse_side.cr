require "./to_one_inverse_side"

# Mapping for the inverse side of a OneToOne association, whose foreign key column is held by the target entity.
class Athena::ORM::Mapping::OneToOneInverseSide < Athena::ORM::Mapping::ToOneInverseSide
  include Athena::ORM::Mapping::OneToOne
end
