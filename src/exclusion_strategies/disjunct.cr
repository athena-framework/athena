require "./exclusion_strategy_interface"

# Wraps an `Array(ASR::ExclusionStrategies::ExclusionStrategyInterface)`, excluding a property if any member skips it.
#
# Used internally to allow multiple exclusion strategies to be used within a single instance variable for `ASR::Context#add_exclusion_strategy`.
struct Athena::Serializer::ExclusionStrategies::Disjunct
  include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface

  # The wrapped exclusion strategies.
  getter members : Array(ASR::ExclusionStrategies::ExclusionStrategyInterface)

  def initialize(@members : Array(ASR::ExclusionStrategies::ExclusionStrategyInterface)); end

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    @members.any?(&.skip_property?(metadata, context))
  end
end
