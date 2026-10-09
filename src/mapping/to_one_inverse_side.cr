# Base class for the inverse side of a to-one association.
#
# The target entity is always loaded eagerly, together with the entity declaring the association.
abstract class Athena::ORM::Mapping::ToOneInverseSide < Athena::ORM::Mapping::InverseSide
  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping, name : String) : self
    if mapping.lazy_proxy
      raise "AORM::Proxy(T) is only valid on owning-side ToOne fields; field '#{mapping.field_name}' on '#{mapping.source_entity}' is the inverse side"
    end

    instance = new mapping

    if instance.id?
      raise "An inverse association is not allowed to be identifier in '#{name}##{instance.field_name}'."
    end

    if instance.orphan_removal?
      instance.cascade << "remove" unless instance.cascade_remove?
      instance.unique = nil
    end

    instance
  end
end
