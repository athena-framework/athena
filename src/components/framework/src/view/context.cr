# Represents (de)serialization options in a serializer agnostic way.
#
# NOTE: These options only apply if the [Serializer bundle](/Serializer/Bundle/) is registered, otherwise data is serialized via `#to_json`.
class Athena::Framework::View::Context
  # Returns the groups that can be used to create different "views" of an object.
  #
  # `ASR::ExclusionStrategies::Groups` is an example of this.
  getter groups : Set(String)? = nil

  # Determines if properties with `nil` values should be emitted.
  property? emit_nil : Bool? = nil

  # Represents the version of an object. Can be used to control what properties are serialized based on the version.
  #
  # `ASR::ExclusionStrategies::Version` is an example of this.
  property version : SemanticVersion? = nil

  # Adds the provided *group* to the `#groups` array.
  def add_group(group : String) : self
    (@groups ||= Set(String).new) << group

    self
  end

  # Adds the provided *groups* to the `#groups` array.
  def add_groups(*groups : String) : self
    self.add_groups groups
  end

  # :ditto:
  def add_groups(groups : Enumerable(String)) : self
    groups.each do |group|
      self.add_group group
    end

    self
  end

  # Sets the `#groups` array to the provided *groups*.
  def groups=(groups : Enumerable(String)) : self
    @groups = groups.to_set

    self
  end

  # Sets the `#version` to the provided *version*.
  def version=(version : String) : self
    self.version = SemanticVersion.parse version

    self
  end
end
