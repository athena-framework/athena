require "./array_collection"

# ORM-aware collection with dirty tracking and lazy loading support.
# Tracks changes since the last snapshot for computing insert/delete diffs.
#
# The ORM puts one in every `AORM::Collection` field it manages, see `AORM::Collection` for how that happens.
# The ORM creates it; application code doesn't construct one.
#
# ## Lazy loading
#
# A collection on an entity loaded from the database doesn't load its elements until it's first read.
# Reading it in any way, such as `#size`, `#each`, `#[]?`, `#includes?`, `#to_a`, `#delete`, `#clear` or `#remove_element`, loads every element with a single query.
# Adding elements with `#<<` doesn't load it; elements added before it's loaded are kept alongside the loaded ones.
#
# ```
# user = em.find! User, 1 # Doesn't query the user's groups
#
# groups = user.groups.as AORM::PersistentCollection(Group)
# groups.loaded? # => false
#
# user.groups.size # Loads the groups
# groups.loaded?   # => true
# ```
#
# WARNING: Loading the collections of many entities one at a time issues one query per collection.
#
# ## Change tracking
#
# Modifying the collection marks it `#dirty?`.
# On the next flush, the elements added and removed since it was loaded, or last flushed, are written to the join table of an owning-side `AORMA::ManyToMany` association.
class Athena::ORM::PersistentCollection(T) < Athena::ORM::AbstractLazyCollection(T)
  @snapshot : Array(T) = [] of T

  # Returns `true` if the collection has been modified since its elements were last synchronized with the database.
  getter? dirty : Bool = false

  # :nodoc:
  #
  # The entity that owns this collection.
  getter owner : AORM::Entity?

  # :nodoc:
  #
  # The association mapping for this collection.
  getter! association : AORM::Mapping::Association

  # :nodoc:
  getter! back_ref_field_name : String
  @collection : AORM::ArrayCollection(T)
  @em : AORM::EntityManagerInterface?
  @class_metadata : AORM::Mapping::ClassInterface?

  # :nodoc:
  #
  # Creates a PersistentCollection backed by an ArrayCollection.
  # Used by the ORM when loading entities.
  def initialize(
    em : AORM::EntityManagerInterface,
    class_metadata : AORM::Mapping::ClassInterface,
    collection : Athena::ORM::ArrayCollection(T),
  )
    @em = em
    @class_metadata = class_metadata
    @collection = collection
    @is_loaded = true
  end

  # :nodoc:
  #
  # Creates an empty PersistentCollection.
  # Primarily for testing or standalone use.
  def initialize
    @collection = AORM::ArrayCollection(T).new
    @is_loaded = true
  end

  # :nodoc:
  #
  # Creates a PersistentCollection with initial elements.
  # Primarily for testing or standalone use.
  def initialize(elements : Array(T))
    @collection = AORM::ArrayCollection(T).new(elements)
    @is_loaded = true
  end

  # :nodoc:
  #
  # Sets the owner entity and association for this collection.
  def set_owner(owner : AORM::Entity, association : AORM::Mapping::Association) : Nil
    @owner = owner
    @association = association
    @back_ref_field_name = if association.is_a?(Mapping::OwningSide)
                             association.inversed_by
                           else
                             association.as(Mapping::InverseSide).mapped_by
                           end
  end

  def each(& : T ->) : Nil
    initialize_collection
    @collection.each do |v|
      yield v
    end
  end

  def size : Int32
    initialize_collection
    @collection.size
  end

  def unsafe_fetch(index) : T
    initialize_collection
    @collection.unsafe_fetch index
  end

  # Returns the element at the given index, or nil if out of bounds.
  def []?(index : Int) : T?
    initialize_collection
    @collection[index]?
  end

  # Sets the element at the given index with dirty tracking.
  def []=(index : Int, value : T) : T
    mark_dirty
    self.cancel_orphan_removal value
    @collection[index] = value
  end

  # Adds an element to the collection with dirty tracking.
  def <<(element : T) : self
    mark_dirty
    self.cancel_orphan_removal element
    @collection << element
    self
  end

  # Removes an element from the collection with dirty tracking.
  def delete(element : T) : T?
    initialize_collection
    if @collection.includes?(element)
      mark_dirty
      removed = @collection.delete(element)
      self.schedule_orphan_removal element
      removed
    end
  end

  # Removes all elements from the collection with dirty tracking.
  def clear : Nil
    initialize_collection
    unless @collection.empty?
      mark_dirty
    end
    @collection.each { |element| self.schedule_orphan_removal element }
    @collection.clear
  end

  # Returns whether the collection contains the element.
  def includes?(element : T) : Bool
    initialize_collection
    @collection.includes?(element)
  end

  # Removes an element and returns whether it was present.
  def remove_element(element : T) : Bool
    initialize_collection
    if @collection.includes?(element)
      mark_dirty
      @collection.delete(element)
      self.schedule_orphan_removal element
      true
    else
      false
    end
  end

  # :nodoc:
  #
  # Polymorphic entry used when the caller only knows `AORM::Entity`
  # (e.g., the UnitOfWork applying pending element removals via
  # `Hash(BasePersistentCollection, Array(Entity))`). The macro guard
  # mirrors `hydrate_add` above so non-entity instantiations don't try to
  # cast `Entity` into a primitive.
  def remove_element(element : AORM::Entity) : Bool
    {% if T <= AORM::Entity %}
      remove_element element.as(T)
    {% else %}
      raise "BUG: Entity overload of remove_element invoked on non-entity collection"
    {% end %}
  end

  # :nodoc:
  #
  # Polymorphic entry used by the hydrator, where the static type of *element*
  # is `AORM::Entity` even though the runtime type matches `T`. The macro guard
  # keeps non-entity instantiations (e.g. `PersistentCollection(Int32)` used in
  # tests) from trying to cast `Entity` into a primitive.
  def hydrate_add(element : AORM::Entity) : Nil
    {% if T <= AORM::Entity %}
      @collection << element.as(T)
    {% else %}
      raise "BUG: Entity overload of hydrate_add invoked on non-entity collection"
    {% end %}
  end

  # :nodoc:
  #
  # Adds an element during hydration without marking dirty.
  def hydrate_add(element : T) : Nil
    @collection << element
  end

  # :nodoc:
  #
  # Sets an element during hydration without marking dirty.
  def hydrate_set(index : Int, element : T) : Nil
    @collection[index] = element
  end

  # Loads the collection's elements, unless they're already loaded.
  def initialize_collection : Nil
    return if @is_loaded || @association.nil?

    # Set loaded early to prevent re-entrancy during do_initialize
    @is_loaded = true
    self.do_initialize
  end

  # :nodoc:
  #
  # Captures the current state for change detection.
  def take_snapshot : Nil
    @snapshot = @collection.to_a
    @dirty = false
  end

  # Returns a copy of the elements array.
  def to_a : Array(T)
    initialize_collection
    @collection.to_a
  end

  # :nodoc:
  #
  # Marks the collection as dirty.
  def mark_dirty : Nil
    @dirty = true
  end

  # :nodoc:
  #
  # Returns a detached copy of this collection. The new instance shares no
  # backing state with the original: the inner collection is copied, owner is
  # nilled out (the caller must `set_owner` on the new entity), the snapshot is
  # cleared, and the copy is marked dirty so it will be persisted on the next
  # flush. Used by the UnitOfWork when a `PersistentCollection` is reassigned
  # to a different owner during change-set computation.
  def clone : self
    initialize_collection
    copy = if (em = @em) && (cm = @class_metadata)
             self.class.new(em, cm, AORM::ArrayCollection(T).new(@collection.to_a))
           else
             self.class.new(@collection.to_a)
           end
    pointerof(copy.@owner).value = nil
    pointerof(copy.@snapshot).value = [] of T
    copy.mark_dirty
    copy
  end

  # :nodoc:
  #
  # Returns elements that were in the snapshot but are no longer present.
  def delete_diff : Array(T)
    @snapshot.reject { |e| @collection.includes?(e) }
  end

  # :nodoc:
  #
  # Returns elements that are present now but were not in the snapshot.
  def insert_diff : Array(T)
    @collection.to_a.reject { |e| @snapshot.includes?(e) }
  end

  # :nodoc:
  #
  # Returns a copy of the snapshot.
  def snapshot : Array(T)
    @snapshot.dup
  end

  # :nodoc:
  #
  # Unwraps the collection to an ArrayCollection for use outside ORM context.
  def unwrap : Collection(T)
    @collection
  end

  # Whether elements removed from this collection are removed from the database too, as configured by the *orphan_removal* option of its association.
  private def orphan_removal? : Bool
    !!((association = @association) && association.is_a?(Mapping::ToMany) && @owner && association.orphan_removal?)
  end

  # Elements arrive typed as their concrete class, and are upcast so the unit of work methods are compiled once rather than once per entity class.
  private def schedule_orphan_removal(element : T) : Nil
    {% if T <= AORM::Entity %}
      @em.try &.unit_of_work.schedule_orphan_removal(element.as(AORM::Entity)) if self.orphan_removal?
    {% end %}
  end

  # An element added back to the collection is no longer an orphan.
  private def cancel_orphan_removal(element : T) : Nil
    {% if T <= AORM::Entity %}
      @em.try &.unit_of_work.cancel_orphan_removal(element.as(AORM::Entity))
    {% end %}
  end

  protected def do_initialize : Nil
    em = @em
    return unless em # Standalone collection without ORM context

    newly_added_dirty_objects = [] of T

    if @dirty
      newly_added_dirty_objects = self.unwrap.to_a
    end

    self.unwrap.clear
    em.unit_of_work.load_collection self
    self.take_snapshot

    unless newly_added_dirty_objects.empty?
      self.restore_new_objects_in_dirty_collection newly_added_dirty_objects
    end
  end

  # Adds back any items that were `<<`'d before the lazy load fired and were not  present in the loaded result.
  protected def restore_new_objects_in_dirty_collection(new_entities : Array(T)) : Nil
    loaded_objects = self.unwrap.to_a
    not_loaded = new_entities.reject { |new_entity| collection_contains?(loaded_objects, new_entity) }

    return if not_loaded.empty?

    not_loaded.each { |entity| @collection << entity }
    @dirty = true
  end

  private def collection_contains?(haystack : Array(T), needle : T) : Bool
    {% if T < Reference %}
      haystack.any?(&.same?(needle))
    {% else %}
      haystack.includes?(needle)
    {% end %}
  end

  def inspect(io)
    io << self.class
  end
end
