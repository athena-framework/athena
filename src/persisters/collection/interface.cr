# :nodoc:
module Athena::ORM::Persisters::Collection::Interface
  abstract def delete(collection : AORM::BasePersistentCollection) : Nil
  abstract def update(collection : AORM::BasePersistentCollection) : Nil
end
