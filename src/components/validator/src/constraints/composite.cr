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
  alias Type = Array(AVD::Constraint) | AVD::Constraint | Enumerable({String | Int32, AVD::Constraint})

  getter constraints : Enumerable({String | Int32, AVD::Constraint})

  def initialize(
    constraints : AVD::Constraints::Composite::Type,
    message : String,
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil,
  )
    super message, groups, payload

    constraints = case constraints
                  when AVD::Constraint then {0 => constraints} of String | Int32 => AVD::Constraint
                  when Array
                    hash = Hash(String | Int32, AVD::Constraint).new initial_capacity: constraints.size

                    constraints.each_with_index do |v, k|
                      hash[k] = v
                    end

                    hash
                  else
                    constraints.transform_keys(&.as(String | Int32))
                  end

    constraints.each_value do |c|
      raise AVD::Exception::Logic.new "The '#{AVD::Constraints::Valid}' constraint cannot be nested inside a '#{self.class}' constraint." if c.is_a? AVD::Constraints::Valid
    end

    if groups.nil?
      merged_groups = Hash(String, Bool).new

      constraints.each_value do |constraint|
        constraint.groups.each do |group|
          merged_groups[group] = true
        end
      end

      @groups = merged_groups.empty? ? [AVD::Constraint::DEFAULT_GROUP] : merged_groups.keys
      @constraints = constraints

      return
    end

    constraints.each_value do |constraint|
      if !constraint.@groups.nil?
        unless (excess_groups = (constraint.groups - self.groups)).empty?
          raise AVD::Exception::Logic.new "The group(s) '#{excess_groups.join ", "}' passed to the constraint '#{constraint.class}' should also be passed to its containing constraint '#{self.class}'."
        end
      else
        constraint.groups = self.groups
      end
    end

    @constraints = constraints
  end

  def add_implicit_group(group : String) : Nil
    super group

    @constraints.each_value &.add_implicit_group(group)
  end
end
