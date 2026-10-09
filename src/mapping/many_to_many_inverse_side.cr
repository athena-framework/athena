require "./inverse_side"
require "./many_to_many"

# Mapping for the inverse side of a ManyToMany association.
# The inverse side does not own the join table.
class Athena::ORM::Mapping::ManyToManyInverseSide < Athena::ORM::Mapping::InverseSide
  include Athena::ORM::Mapping::ManyToMany

  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping) : self
    instance = new(
      mapping.field_name,
      mapping.source_entity.not_nil!,
      mapping.target_entity.not_nil!,
      mapping.mapped_by.not_nil!,
      mapping.fetch_mode,
      nil, # id is always nil for to-many
      mapping.orphan_removal,
      nil, # unique is not applicable
      mapping.cascade,
    )

    instance.index_by = mapping.index_by

    if instance.orphan_removal?
      unless instance.cascade_remove?
        instance.cascade << "remove"
      end
    end

    instance
  end

  # Optional index column for indexed collections.
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
  def many_to_many? : Bool
    true
  end

  # :nodoc:
  def to_many? : Bool
    true
  end
end
