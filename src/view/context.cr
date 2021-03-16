# Represents (de)serialization options in a serializer agnostic way.
class Athena::Routing::View::Context
  getter groups : Set(String)? = nil
  property? emit_nil : Bool? = nil
  property version : SemanticVersion? = nil

  getter exclusion_strategies = Array(ASR::ExclusionStrategies::ExclusionStrategyInterface).new

  def add_exclusion_strategy(strategy : ASR::ExclusionStrategies::ExclusionStrategyInterface) : self
    @exclusion_strategies << strategy

    self
  end

  def add_group(group : String) : self
    (@groups ||= Set(String).new) << group

    self
  end

  def add_groups(*groups : String) : self
    self.add_groups groups
  end

  def add_groups(groups : Enumerable(String)) : self
    groups.each do |group|
      self.add_group group
    end

    self
  end

  def groups=(groups : Enumerable(String)) : self
    @groups = groups.to_set

    self
  end

  def version=(version : String) : self
    self.version = SemanticVersion.parse version

    self
  end
end
