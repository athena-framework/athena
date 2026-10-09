require "./to_one"

# Marker module for ManyToOne associations, see `AORMA::ManyToOne`.
module Athena::ORM::Mapping::ManyToOne
  include Athena::ORM::Mapping::ToOne
end
