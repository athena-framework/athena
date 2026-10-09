require "./inverse_side"
require "./one_to_many"

# Mapping for the inverse side of a OneToMany association.
# OneToMany is always the inverse side; the corresponding ManyToOne owns the FK.
#
# Its `#mapped_by` names the `AORMA::ManyToOne` property on the target entity, and is required: building the metadata of an entity raises without it.
class Athena::ORM::Mapping::OneToManyInverseSide < Athena::ORM::Mapping::InverseSide
  include Athena::ORM::Mapping::OneToMany

  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping) : self
    raise "OneToMany requires `mapped_by`" unless mapping.mapped_by

    instance = new(
      mapping.field_name,
      mapping.source_entity.not_nil!,
      mapping.target_entity.not_nil!,
      mapping.mapped_by.not_nil!,
      mapping.fetch_mode,
      nil,
      mapping.orphan_removal,
      nil,
      mapping.cascade,
    )

    instance.index_by = mapping.index_by

    if instance.orphan_removal? && !instance.cascade_remove?
      instance.cascade << "remove"
    end

    instance
  end

  # The name of the target's field to index the collection by.
  #
  # TODO: Recorded, but collections aren't indexed by it yet.
  property index_by : String?

  # :nodoc:
  def initialize(
    field_name : String,
    source_entity : AORM::Entity.class,
    target_entity : AORM::Entity.class,
    mapped_by : String,
    fetch_mode : FetchMode? = nil,
    id : Bool? = nil,
    orphan_removal : Bool? = false,
    unique : Bool? = nil,
    cascade : Array(String)? = nil,
  )
    super field_name, source_entity, target_entity, mapped_by, fetch_mode, id, orphan_removal || false, unique, cascade
  end

  # :nodoc:
  def one_to_many? : Bool
    true
  end

  # :nodoc:
  def to_many? : Bool
    true
  end
end
