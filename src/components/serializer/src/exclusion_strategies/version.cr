require "./exclusion_strategy_interface"

# Serialize properties based on a `SemanticVersion` string.
#
# It is enabled by default when using `ASR::Context#version=`.
#
# ```
# class Example
#   include ASR::Serializable
#
#   def initialize; end
#
#   @[ASRA::Until("1.0.0")]
#   property name : String = "Legacy Name"
#
#   @[ASRA::Since("1.1.0")]
#   property name2 : String = "New Name"
# end
#
# obj = Example.new
#
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.version = "0.30.0" # => {"name":"Legacy Name"}
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.version = "1.2.0"  # => {"name2":"New Name"}
# ```
struct Athena::Serializer::ExclusionStrategies::Version
  include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface

  getter version : SemanticVersion

  def initialize(@version : SemanticVersion); end

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    # Skip if *version* is not at least *since_version*.
    return true if (since_version = metadata.since_version) && @version < since_version

    # Skip if *version* is greater than or equal to than *until_version*.
    return true if (until_version = metadata.until_version) && @version >= until_version

    false
  end
end
