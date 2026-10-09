# Base class for the owning side of an association: the side whose changes are written to the database.
#
# The owning side holds the foreign key column, or manages the join table of a many-to-many association.
# A `AORMA::ManyToOne` association is always the owning side, as is a `AORMA::OneToOne` or `AORMA::ManyToMany` association without `mapped_by`.
# Changes made only to the inverse side of a bidirectional association aren't persisted, so keep both sides in sync, or at least update the owning side.
abstract class Athena::ORM::Mapping::OwningSide < Athena::ORM::Mapping::Association
  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping) : self
    new(
      mapping.field_name,
      mapping.source_entity.not_nil!,
      mapping.target_entity.not_nil!,
      mapping.inversed_by.not_nil!,
      mapping.fetch_mode,
      mapping.id,
      mapping.orphan_removal,
      mapping.unique,
      mapping.cascade,
    )
  end

  # The name of the property on the target entity that holds the inverse side, if the association is bidirectional.
  property inversed_by : String?

  # :nodoc:
  def initialize(
    field_name : String,
    source_entity : AORM::Entity.class,
    target_entity : AORM::Entity.class,
    @inversed_by : String?,
    fetch_mode : FetchMode? = nil,
    id : Bool? = nil,
    orphan_removal : Bool? = false,
    unique : Bool? = nil,
    cascade : Array(String)? = nil,
  )
    super field_name, source_entity, target_entity, fetch_mode, id, orphan_removal || false, unique, cascade
  end
end
