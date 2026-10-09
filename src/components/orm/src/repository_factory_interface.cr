# Creates the repositories returned by `AORM::EntityManager#repository`.
#
# See `AORM::DefaultRepositoryFactory` for the default implementation.
#
# TODO: A custom repository factory can't be configured yet.
module Athena::ORM::RepositoryFactoryInterface
  # Returns the repository of *entity_class* for *em*.
  abstract def repository(em : AORM::EntityManagerInterface, entity_class : AORM::Entity.class)
end
