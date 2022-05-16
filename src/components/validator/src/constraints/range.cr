# Validates that a `Number` or `Time` value is between some minimum and maximum.
#
# # Configuration
#
# ## Required Arguments
#
# ### range
#
# **Type:** `::Range`
#
# The `::Range` that defines the minimum and maximum values, if any.
# An endless range can be used to only have a minimum or maximum.
#
# ## Optional Arguments
#
# NOTE: This constraint does not support a `message` argument.
#
# ### not_in_range_message
#
# **Type:** `String` **Default:** `This value should be between {{ min }} and {{ max }}.`
#
# The message that will be shown if the value is less than the min or greater than the max.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ min }}` - The lower limit.
# * `{{ max }}` - The upper limit.
#
# ### min_message
#
# **Type:** `String` **Default:** `This value should be {{ limit }} or more.`
#
# The message that will be shown if the value is less than the min, and no max has been provided.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ limit }}` - The lower limit.
#
# ### max_message
#
# **Type:** `String` **Default:** `This value should be {{ limit }} or less.`
#
# The message that will be shown if the value is more than the max, and no min has been provided.
#
# #### Placeholders
#
# The following placeholders can be used in this message:
#
# * `{{ value }}` - The current (invalid) value.
# * `{{ limit }}` - The upper limit.
#
# ### groups
#
# **Type:** `Array(String) | String | Nil` **Default:** `nil`
#
# The [validation groups][Athena::Validator::Constraint--validation-groups] this constraint belongs to.
# `AVD::Constraint::DEFAULT_GROUP` is assumed if `nil`.
#
# ### payload
#
# **Type:** `Hash(String, String)?` **Default:** `nil`
#
# Any arbitrary domain-specific data that should be stored with this constraint.
# The [payload][Athena::Validator::Constraint--payload] is not used by `Athena::Validator`, but its processing is completely up to you.
class Athena::Validator::Constraints::Range < Athena::Validator::Constraint
  NOT_IN_RANGE_ERROR = "7e62386d-30ae-4e7c-918f-1b7e571c6d69"
  TOO_HIGH_ERROR     = "5d9aed01-ac49-4d8e-9c16-e4aab74ea774"
  TOO_LOW_ERROR      = "f0316644-882e-4779-a404-ee7ac97ddecc"

  @@error_names = {
    NOT_IN_RANGE_ERROR => "NOT_IN_RANGE_ERROR",
    TOO_HIGH_ERROR     => "TOO_HIGH_ERROR",
    TOO_LOW_ERROR      => "TOO_LOW_ERROR",
  }

  getter min : Number::Primitive | Time | Nil
  getter max : Number::Primitive | Time | Nil
  getter not_in_range_message : String
  getter min_message : String
  getter max_message : String

  def self.new(
    range : ::Range,
    not_in_range_message : String = "This value should be between {{ min }} and {{ max }}.",
    min_message : String = "This value should be {{ limit }} or more.",
    max_message : String = "This value should be {{ limit }} or less.",
    groups : Array(String) | String | Nil = nil,
    payload : Hash(String, String)? = nil
  )
    range_end = range.end

    if range_end && range_end.is_a? Number::Primitive && range.excludes_end?
      range_end -= 1
    end

    new range.begin, range_end, not_in_range_message, min_message, max_message, groups, payload
  end

  private def initialize(
    @min : Number::Primitive | Time | Nil,
    @max : Number::Primitive | Time | Nil,
    @not_in_range_message : String,
    @min_message : String,
    @max_message : String,
    groups : Array(String) | String | Nil,
    payload : Hash(String, String)?
  )
    super "", groups, payload
  end

  class Validator < Athena::Validator::ConstraintValidator
    # :inherit:
    #
    # ameba:disable Metrics/CyclomaticComplexity
    def validate(value : Number | Time | Nil, constraint : AVD::Constraints::Range) : Nil
      return if value.nil?

      min = constraint.min
      max = constraint.max

      case {value, min, max}
      when {Number, Number::Primitive?, Number::Primitive?}
        return self.add_not_in_range_violation constraint, value, min, max if min && max && (value < min || value > max)
        return self.add_too_high_violation constraint, value, max if max && value > max

        add_too_low_violation constraint, value, min if min && value < min
      when {Time, Time?, Time?}
        return self.add_not_in_range_violation constraint, value, min, max if min && max && (value < min || value > max)
        return self.add_too_high_violation constraint, value, max if max && value > max

        add_too_low_violation constraint, value, min if min && value < min
      end
    end

    def validate(value : _, constraint : AVD::Constraints::Range) : Nil
      raise AVD::Exceptions::UnexpectedValueError.new value, "Number | Time"
    end

    private def add_not_in_range_violation(constraint, value, min, max) : Nil
      self
        .context
        .build_violation(constraint.not_in_range_message, NOT_IN_RANGE_ERROR, value)
        .add_parameter("{{ min }}", min)
        .add_parameter("{{ max }}", max)
        .add
    end

    private def add_too_high_violation(constraint, value, max) : Nil
      self
        .context
        .build_violation(constraint.max_message, TOO_HIGH_ERROR, value)
        .add_parameter("{{ limit }}", max)
        .add
    end

    private def add_too_low_violation(constraint, value, min) : Nil
      self
        .context
        .build_violation(constraint.min_message, TOO_LOW_ERROR, value)
        .add_parameter("{{ limit }}", min)
        .add
    end
  end
end
