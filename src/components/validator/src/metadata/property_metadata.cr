require "./property_metadata_interface"

class Athena::Validator::Metadata::PropertyMetadata(EntityType, PropertyIdx)
  include Athena::Validator::Metadata::GenericMetadata
  include Athena::Validator::Metadata::PropertyMetadataInterface

  # :inherit:
  getter name : String

  def initialize(@name : String); end

  # Returns the class the property `self` represents, belongs to.
  def class_name : EntityType.class
    EntityType
  end

  protected def value(obj : EntityType)
    {% begin %}
      {% unless PropertyIdx == Nil %}
        obj.@{{EntityType.instance_vars[PropertyIdx].name.id}}
      {% else %}
        case @name
          {% for ivar in EntityType.instance_vars %}
            when {{ivar.name.stringify}} then obj.@{{ivar.id}}
          {% end %}
        else
          raise "BUG: Unknown property '#{@name}' within #{EntityType}."
        end
      {% end %}
    {% end %}
  end
end
