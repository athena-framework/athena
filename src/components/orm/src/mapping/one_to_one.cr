require "./to_one"

# Marker module for OneToOne associations, see `AORMA::OneToOne`.
module Athena::ORM::Mapping::OneToOne
  include Athena::ORM::Mapping::ToOne
end
