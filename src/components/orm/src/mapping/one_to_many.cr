require "./to_many"

# Marker module for OneToMany associations, see `AORMA::OneToMany`.
module Athena::ORM::Mapping::OneToMany
  include Athena::ORM::Mapping::ToMany
end
