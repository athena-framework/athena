# Base class for all association mappings.
# Contains common properties shared by all association types.
#
# An association mapping describes an association property, as configured by `AORMA::OneToOne`, `AORMA::ManyToOne`, `AORMA::OneToMany`, or `AORMA::ManyToMany`.
# The mappings of an entity are available from its class metadata:
#
# ```
# mapping = em.class_metadata(User).association_mappings["groups"]
#
# mapping.target_entity    # => Group
# mapping.cascade_persist? # => true
# ```
#
# Each mapping is either an `AORM::Mapping::OwningSide` or an `AORM::Mapping::InverseSide`, and includes the module of its kind: `AORM::Mapping::OneToOne`, `AORM::Mapping::ManyToOne`, `AORM::Mapping::OneToMany`, or `AORM::Mapping::ManyToMany`.
abstract class Athena::ORM::Mapping::Association
  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping) : self
    new(
      mapping.field_name,
      mapping.source_entity,
      mapping.target_entity,
      mapping.fetch_mode,
      mapping.id,
      mapping.orphan_removal,
      mapping.unique,
      mapping.cascade,
    )
  end

  # The name of the field in the entity that holds this association.
  property field_name : String

  # The entity class that declares this association.
  property source_entity : AORM::Entity.class

  # The entity class this association references.
  property target_entity : AORM::Entity.class

  # The fetch strategy for loading the association.
  #
  # TODO: The fetch mode is recorded, but doesn't affect loading yet; see `AORM::Mapping::FetchMode`.
  property fetch_mode : FetchMode?

  # Whether this association is part of the identifier.
  property? id : Bool?

  # Whether a target entity that's no longer referenced through this association is removed on flush.
  # Enabling it also cascades `remove` operations.
  property? orphan_removal : Bool

  # Whether the database deletes the join table rows of a removed entity on its own, because the association's join columns are declared `ON DELETE CASCADE`.
  # Default many-to-many join columns are, as are those given `on_delete: "CASCADE"`.
  property? on_delete_cascade : Bool = false

  # Whether the association should be unique.
  property? unique : Bool?

  # The operations cascaded from the source entity to the target entities, in lower case.
  # `"all"` in the mapping is expanded to `remove`, `persist`, `refresh`, and `detach`.
  getter cascade : Array(String)

  # :nodoc:
  def initialize(
    @field_name : String,
    @source_entity : AORM::Entity.class,
    @target_entity : AORM::Entity.class,
    @fetch_mode : FetchMode? = nil,
    @id : Bool? = nil,
    @orphan_removal : Bool? = false,
    @unique : Bool? = nil,
    cascade : Array(String)? = nil,
  )
    @cascade = cascade || [] of String
  end

  # Whether `AORM::EntityManager#persist` cascades to the target entities.
  def cascade_persist? : Bool
    @cascade.includes? "persist"
  end

  # Whether `AORM::EntityManager#remove` cascades to the target entities.
  def cascade_remove? : Bool
    @cascade.includes? "remove"
  end

  # Whether `AORM::EntityManager#detach` cascades to the target entities.
  def cascade_detach? : Bool
    @cascade.includes? "detach"
  end

  # Returns the kind of association: `"one_to_one"`, `"many_to_one"`, `"one_to_many"`, or `"many_to_many"`.
  #
  # TODO: Make this an enum
  def type : String
    # ManyToOne is also ToOne (and a kind of OneToOne in our hierarchy via ToOneOwningSide), so check the more specific markers first.
    return "many_to_one" if self.is_a? ManyToOne
    return "one_to_many" if self.is_a? OneToMany
    return "many_to_many" if self.is_a? ManyToMany
    return "one_to_one" if self.is_a? OneToOne

    raise "Cannot determine type for #{self.class}"
  end
end
