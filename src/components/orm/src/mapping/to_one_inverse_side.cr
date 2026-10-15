# Base class for the inverse side of a to-one association.
#
# The target entity is always loaded eagerly, together with the entity declaring the association.
abstract class Athena::ORM::Mapping::ToOneInverseSide < Athena::ORM::Mapping::InverseSide
  # :nodoc:
  def self.new(mapping : Driver::ColumnMapping, name : String) : self
    if mapping.lazy_proxy
      raise AORM::Exception::Mapping.proxy_not_allowed_on_to_one_inverse_side mapping.source_entity.to_s, mapping.field_name
    end

    instance = new mapping

    if instance.id?
      raise AORM::Exception::Mapping.illegal_inverse_identifier_association name, instance.field_name
    end

    if instance.orphan_removal?
      instance.cascade << "remove" unless instance.cascade_remove?
      instance.unique = nil
    end

    instance
  end
end
