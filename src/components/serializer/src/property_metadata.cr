# Parent type of a property metadata just used for typing.
#
# See `ASR::PropertyMetadata`.
module Athena::Serializer::PropertyMetadataBase; end

# Stores metadata related to a specific property.
#
# This includes its name (internal and external), value, versions/groups, and any aliases.
struct Athena::Serializer::PropertyMetadata(IvarType, ValueType, ClassType)
  include Athena::Serializer::PropertyMetadataBase

  # The name of the property.
  getter name : String

  # The name that should be used for serialization/deserialization.
  getter external_name : String

  # The value of the property (when serializing).
  getter value : ValueType

  # The type of the property.
  getter type : IvarType.class = IvarType

  # The class that the property is part of.
  getter class : ClassType.class = ClassType

  # Represents the first version this property is available.
  #
  # See `ASR::ExclusionStrategies::Version`.
  property since_version : SemanticVersion?

  # Represents the last version this property was available.
  #
  # See `ASR::ExclusionStrategies::Version`.
  property until_version : SemanticVersion?

  # The serialization groups this property belongs to.
  #
  # See `ASR::ExclusionStrategies::Groups`.
  getter groups : Set(String) = Set{"default"}

  # Deserialize this property from the property's name or any name in *aliases*.
  #
  # See `ASRA::Name`.
  getter aliases : Array(String)

  # If this property should not be serialized if it is empty.
  #
  # See `ASRA::SkipWhenEmpty`.
  getter? skip_when_empty : Bool

  # Returns annotations configurations registered via `ADI..configuration_annotation` and applied to this property.
  #
  # These configurations could then be accessed within an `ASR::ExclusionStrategies::ExclusionStrategyInterface`.
  getter annotation_configurations : ADI::AnnotationConfigurations

  def initialize(
    @name : String,
    @external_name : String,
    @annotation_configurations : ADI::AnnotationConfigurations,
    @value : ValueType = nil,
    @skip_when_empty : Bool = false,
    groups : Enumerable(String) = ["default"],
    @aliases : Array(String) = [] of String,
    @since_version : SemanticVersion? = nil,
    @until_version : SemanticVersion? = nil,
    @type : IvarType.class = IvarType,
    @class : ClassType.class = ClassType,
  )
    @groups = groups.to_set
  end
end
