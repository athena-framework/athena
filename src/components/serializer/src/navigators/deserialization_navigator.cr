module Athena::Serializer::Navigators::DeserializationNavigatorInterface
  abstract def accept(type : T.class, data : ASR::Any) forall T
end

struct Athena::Serializer::Navigators::DeserializationNavigator
  include Athena::Serializer::Navigators::DeserializationNavigatorInterface

  def initialize(
    @visitor : ASR::Visitors::DeserializationVisitorInterface,
    @context : ASR::DeserializationContext,
    @object_constructor : ASR::ObjectConstructorInterface
  ); end

  def accept(type : T.class, data : ASR::Any) forall T
    {% unless T.instance <= ASR::Model %}
      {% if T.class.has_method? :deserialize %}
        @visitor.visit type, data
      {% end %}
    {% else %}
      {% if ann = T.instance.annotation(ASRA::Discriminator) %}
        if key = data[{{ann[:key]}}]?
          type = case key
            {% for k, t in ann[:map] %}
              when {{k.id.stringify}} then {{t}}
            {% end %}
          else
            raise ASR::Exception::PropertyException.new "Unknown '#{{{ann[:key]}}}' discriminator value: '#{key}'.", {{ann[:key].id.stringify}}
          end
        else
          raise ASR::Exception::PropertyException.new "Missing discriminator field '#{{{ann[:key]}}}'.", {{ann[:key].id.stringify}}
        end
      {% end %}

      properties = type.deserialization_properties

      # Apply exclusion strategies if one is defined
      if strategy = @context.exclusion_strategy
        properties.reject! { |property| strategy.skip_property? property, @context }
      end

      object = @object_constructor.construct self, properties, data, type

      object.run_postdeserialize

      object
    {% end %}
  end
end
