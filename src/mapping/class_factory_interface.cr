# :nodoc:
module Athena::ORM::Mapping::ClassFactoryInterface
  abstract def metadata(for entity_class : AORM::Entity.class) : AORM::Mapping::ClassInterface
end
