# The type of an entity's `AORMA::OneToMany` and `AORMA::ManyToMany` association fields.
#
# Type the property as `AORM::Collection(T)`, where *T* is the associated entity, and initialize it with an empty `AORM::ArrayCollection(T)`:
#
# ```
# @[AORMA::Entity]
# class User < AORM::Entity
#   # ...
#
#   @[AORMA::ManyToMany(inversed_by: "users")]
#   property groups : AORM::Collection(Group) = AORM::ArrayCollection(Group).new
#
#   # Keeps both sides of the association in sync in memory.
#   def add_group(group : Group) : Nil
#     self.groups << group
#     group.users << self
#   end
# end
#
# user = User.new
# user.add_group Group.new # Works before the user is ever persisted
# ```
#
# WARNING: The default value is required, since the ORM reads the element type from it.
#
# The ORM swaps the collection for an `AORM::PersistentCollection(T)`:
#
# * When a flush processes the entity, any other collection assigned to the field is replaced by a persistent one holding the same elements.
# * When the entity is loaded from the database, the field holds a persistent collection whose elements aren't loaded yet.
#   They're loaded with a single query the first time the collection is read, see `AORM::PersistentCollection`.
#
# So code should only rely on the `AORM::Collection(T)` API, not on the field holding a specific implementation.
# Both implementations are `Indexable(T)`, so the usual `Enumerable` and `Indexable` methods are available alongside `<<`, `delete`, `remove_element`, `includes?` and `clear`.
#
# ## Owning and inverse sides
#
# Only changes to the owning side of an association are written to the database.
# Adding an element to, or removing one from, a `AORMA::ManyToMany` collection without `mapped_by` inserts or deletes its row in the join table on the next flush.
# A `AORMA::OneToMany` collection is always the inverse side: the foreign key lives on the element's `AORMA::ManyToOne` field, so set that field for the change to be written.
# Changes made only to an inverse side are ignored, so keep both sides in sync, as `add_group` does above.
#
# New entities added to a collection are only inserted if they're persisted themselves, or the association is mapped with `cascade: ["persist"]`; otherwise the flush raises.
# Once a flush deletes an entity, it's also removed from the loaded collections of managed entities that still contained it.
module Athena::ORM::Collection(T)
end

# :nodoc:
#
# Non-generic ancestor of every collection implementation.
abstract class Athena::ORM::BaseCollection
end

# :nodoc:
#
# Non-generic ancestor of every persistent collection, declaring what the unit of work and persisters use through it.
# A union of different `PersistentCollection(T)` instances collapses to this class, so it must provide everything callers need.
abstract class Athena::ORM::BasePersistentCollection < Athena::ORM::BaseCollection
  # Collection implementations are generic instances, which the compiler would otherwise create one at a time while typing the program.
  # Each new one re-types every call already typed through `BaseCollection` or this class, which made compile time grow quadratically with the number of entities.
  # Declaring the collection types of every entity before any code is typed avoids that, and also guarantees these abstract classes have concrete implementations whatever order code is compiled in.
  macro finished
    {% for entity, idx in Athena::ORM::Entity.all_subclasses.reject { |t| t.abstract? || t <= Athena::ORM::Proxy } %}
      @@persistent_collection_{{idx}} : AORM::PersistentCollection({{entity.id}})? = nil
      @@array_collection_{{idx}} : AORM::ArrayCollection({{entity.id}})? = nil
    {% end %}
  end

  abstract def owner : AORM::Entity?
  abstract def association : AORM::Mapping::Association
  abstract def set_owner(owner : AORM::Entity, association : AORM::Mapping::Association) : Nil
  abstract def dirty? : Bool
  abstract def initialize_collection : Nil
  abstract def take_snapshot : Nil
  abstract def remove_element(element : AORM::Entity) : Bool
  abstract def hydrate_add(element : AORM::Entity) : Nil
  abstract def unwrap
  abstract def clone
  abstract def delete_diff
  abstract def insert_diff
end
