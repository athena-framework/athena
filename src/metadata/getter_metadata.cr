require "./property_metadata_interface"

class Athena::Validator::Metadata::GetterMetadata(EntityType, MethodIdx)
  include Athena::Validator::Metadata::GenericMetadata
  include Athena::Validator::Metadata::PropertyMetadataInterface

  # :inherit:
  getter name : String

  def initialize(@name : String); end

  # Returns the class the method `self` represents, belongs to.
  def class_name : EntityType.class
    EntityType
  end

  protected def value(obj : EntityType)
    {% begin %}
      {% unless MethodIdx == Nil %}
        obj.{{EntityType.methods[MethodIdx].name.id}}
      {% else %}
        case @name
          {% for m in EntityType.methods.reject &.name.ends_with? '=' %}
            when {{m.name.stringify}} then obj.{{m.name.id}}
          {% end %}
        else
          raise "BUG: Unknown method '#{@name}' within #{EntityType}."
        end
      {% end %}
    {% end %}
  end
end
