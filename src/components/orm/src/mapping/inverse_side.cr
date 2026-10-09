# Base class for the side of a bidirectional association whose mapping points at the owning side via `mapped_by`.
# The owning side is where the foreign key (or join-table reference) lives; the inverse side is read-only with respect to the relationship.
#
# A `AORMA::OneToMany` association is always the inverse side, as is a `AORMA::OneToOne` or `AORMA::ManyToMany` association with `mapped_by`.
# Changes made only to the inverse side aren't persisted, so keep both sides in sync, or at least update the owning side.
abstract class Athena::ORM::Mapping::InverseSide < Athena::ORM::Mapping::Association
  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping) : self
    new(
      mapping.field_name,
      mapping.source_entity.not_nil!,
      mapping.target_entity.not_nil!,
      mapping.mapped_by.not_nil!,
      mapping.fetch_mode,
      mapping.id,
      mapping.orphan_removal,
      mapping.unique,
      mapping.cascade,
    )
  end

  # The name of the field on the owning side that completes the bidirectional association.
  property mapped_by : String

  # :nodoc:
  def initialize(
    field_name : String,
    source_entity : AORM::Entity.class,
    target_entity : AORM::Entity.class,
    @mapped_by : String,
    fetch_mode : FetchMode? = nil,
    id : Bool? = nil,
    orphan_removal : Bool? = false,
    unique : Bool? = nil,
    cascade : Array(String)? = nil,
  )
    super field_name, source_entity, target_entity, fetch_mode, id, orphan_removal || false, unique, cascade
  end
end
