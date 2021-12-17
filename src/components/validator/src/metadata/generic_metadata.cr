require "./metadata_interface"

module Athena::Validator::Metadata::GenericMetadata
  include Athena::Validator::Metadata::MetadataInterface

  @constraints_by_group = {} of String => Array(AVD::Constraint)

  getter constraints : Array(AVD::Constraint) = [] of AVD::Constraint

  # :inherit:
  getter cascading_strategy : AVD::Metadata::CascadingStrategy = AVD::Metadata::CascadingStrategy::None

  # Adds the provided *constraint* to `self`'s `#constraints` array.
  #
  # Sets `#cascading_strategy` to `AVD::Metadata::CascadingStrategy::Cascade` if the *constraint* is `AVD::Constraints::Valid`.
  def add_constraint(constraint : AVD::Constraint) : AVD::Metadata::GenericMetadata
    if constraint.is_a? AVD::Constraints::Valid
      @cascading_strategy = :cascade

      return self
    end

    @constraints << constraint

    constraint.groups.each do |group|
      (@constraints_by_group[group] ||= Array(AVD::Constraint).new) << constraint
    end

    self
  end

  # Adds each of the provided *constraints* to `self`.
  def add_constraints(constraints : Array(AVD::Constraint)) : AVD::Metadata::GenericMetadata
    constraints.each &->add_constraint(AVD::Constraint)

    self
  end

  # :inherit:
  def find_constraints(group : String) : Array(AVD::Constraint)
    @constraints_by_group[group]? || Array(AVD::Constraint).new
  end

  protected def value(entity : AVD::Validatable)
    raise "BUG: Invoked default value method."
  end
end
