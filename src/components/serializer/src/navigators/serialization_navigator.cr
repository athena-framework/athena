module Athena::Serializer::Navigators::SerializationNavigatorInterface
  abstract def accept(data : ASR::Model) : Nil
  abstract def accept(data : _) : Nil
end

struct Athena::Serializer::Navigators::SerializationNavigator
  include Athena::Serializer::Navigators::SerializationNavigatorInterface

  def initialize(@visitor : ASR::Visitors::SerializationVisitorInterface, @context : ASR::SerializationContext); end

  def accept(data : ASR::Model) : Nil
    data.run_preserialize

    properties = data.serialization_properties

    # Apply exclusion strategies if one is defined
    if strategy = @context.exclusion_strategy
      properties.reject! { |property| strategy.skip_property? property, @context }
    end

    # Reject properties that should be skipped when empty
    # or properties that should be skipped when nil
    properties.reject! do |property|
      val = property.value
      skip_when_empty = property.skip_when_empty? && val.responds_to? :empty? && val.empty?
      skip_nil = !@context.emit_nil? && val.nil?

      skip_when_empty || skip_nil
    end

    # Process properties
    @visitor.visit properties

    data.run_postserialize
  end

  def accept(data : _) : Nil
    @visitor.visit data
  end
end
