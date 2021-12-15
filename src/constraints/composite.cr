# A constraint composed of other constraints.
# handles normalizing the groups of the nested constraints, via the following algorithm:
#
# * If groups are passed explicitly to the composite constraint, but
#   not to the nested constraints, the options of the composite
#   constraint are copied to the nested constraints
# * If groups are passed explicitly to the nested constraints, but not
#   to the composite constraint, the groups of all nested constraints
#   are merged and used as groups for the composite constraint
# * If groups are passed explicitly to both the composite and its nested
#   constraints, the groups of the nested constraints must be a subset
#   of the groups of the composite constraint.
#
# NOTE: You most likely want to use `AVD::Constraints::Compound` instead of this type.
abstract class Athena::Validator::Constraints::Composite < Athena::Validator::Constraint
  getter constraints : Array(AVD::Constraint) = [] of AVD::Constraint

  def initialize(
    constraints : Array(AVD::Constraint) | AVD::Constraint,
    message : String,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    super message, groups, payload

    unless constraints.is_a? Array
      constraints = [constraints] of AVD::Constraint
    end

    # TODO: Prevent `Valid` constraints

    if groups.nil?
      merged_groups = Hash(String, Bool).new

      constraints.each do |constraint|
        constraint.groups.each do |group|
          merged_groups[group] = true
        end
      end

      @groups = merged_groups.empty? ? [AVD::Constraint::DEFAULT_GROUP] : merged_groups.keys
      @constraints = constraints

      return
    end

    constraints.each do |constraint|
      # if !constraint.groups.nil?
      #   # TODO: Validate there are no excess groups
      # else
      constraint.groups = self.groups
      # end
    end

    @constraints = constraints
  end

  def add_implicit_group(group : String) : Nil
    super group

    @constraints.each &.add_implicit_group(group)
  end
end
