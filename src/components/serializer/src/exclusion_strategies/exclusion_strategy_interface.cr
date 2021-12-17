# Represents a specific exclusion strategy.
#
# Custom logic can be implemented by defining a type with this interface.
# It can then be used via `ASR::Context#add_exclusion_strategy`.
#
# ## Example
#
# ```
# struct OddNumberExclusionStrategy
#   include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface
#
#   # :inherit:
#   #
#   # Skips serializing odd numbered values
#   def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
#     # Don't skip if the value is nil
#     return false unless value = (metadata.value)
#
#     # Only skip on serialization, if the value is an number, and if it's odd.
#     context.is_a?(ASR::SerializationContext) && value.is_a?(Number) && value.odd?
#   end
# end
#
# serialization_context = ASR::SerializationContext.new
# serialization_context.add_exclusion_strategy OddNumberExclusionStrategy.new
#
# deserialization_context = ASR::DeserializationContext.new
# deserialization_context.add_exclusion_strategy OddNumberExclusionStrategy.new
#
# record Values, one : Int32 = 1, two : Int32 = 2, three : Int32 = 3 do
#   include ASR::Serializable
# end
#
# ASR.serializer.serialize Values.new, :json, serialization_context                                 # => {"two":2}
# ASR.serializer.deserialize Values, %({"one":4,"two":5,"three":6}), :json, deserialization_context # => Values(@one=4, @three=6, @two=5)
# ```
#
# ### Annotation Configurations
#
# Custom annotations can be defined using `Athena::Config.configuration_annotation`.
# These annotations will be exposed at runtime as part of the properties' metadata within exclusion strategies via `ASR::PropertyMetadata#annotation_configurations`.
# The main purpose of this is to allow for more advanced annotation based exclusion strategies.
#
# ```
# # Define an annotation called `IsActiveProperty` that accepts an optional `active` field.
# ACF.configuration_annotation IsActiveProperty, active : Bool = true
#
# # Define an exclusion strategy that should skip "inactive" properties.
# struct ActivePropertyExclusionStrategy
#   include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface
#
#   # :inherit:
#   def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
#     # Don't skip on deserialization.
#     return false if context.direction.deserialization?
#
#     ann_configs = metadata.annotation_configurations
#
#     # Skip if the property has the annotation and it's "inactive".
#     ann_configs.has?(IsActiveProperty) && !ann_configs[IsActiveProperty].active
#   end
# end
#
# record Example, id : Int32, first_name : String, last_name : String, zip_code : Int32 do
#   include ASR::Serializable
#
#   @[IsActiveProperty]
#   @first_name : String
#
#   @[IsActiveProperty(active: false)]
#   @last_name : String
#
#   # Can also be defined as a positional argument.
#   @[IsActiveProperty(false)]
#   @zip_code : Int32
# end
#
# serialization_context = ASR::SerializationContext.new
# serialization_context.add_exclusion_strategy ActivePropertyExclusionStrategy.new
#
# ASR.serializer.serialize Example.new(1, "Jon", "Snow", 90210), :json, serialization_context # => {"id":1,"first_name":"Jon"}
# ```
module Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface
  # Returns `true` if a property should _NOT_ be (de)serialized.
  abstract def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
end
