require "./collection"

# Base type of collections whose elements are loaded on first access.
#
# See `AORM::PersistentCollection`.
abstract class Athena::ORM::AbstractLazyCollection(T) < Athena::ORM::BasePersistentCollection
  include Athena::ORM::Collection(T)
  include Indexable(T)

  # @collection : Athena::ORM::Collection
  @is_loaded : Bool = false

  # Returns `true` if the collection's elements are in memory: either it has been loaded, or it was created in memory rather than loaded from the database.
  def loaded? : Bool
    @is_loaded
  end

  # :nodoc:
  def initialized=(value : Bool) : Bool
    @is_loaded = value
  end
end
