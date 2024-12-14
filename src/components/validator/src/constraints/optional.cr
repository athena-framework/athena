# Allows wrapping `AVD::Constraint`(s) to denote it as being optional within an `AVD::Constraints::Collection`.
# See [this][Athena::Validator::Constraints::Collection--required-and-optional-constraints] for more information.
class Athena::Validator::Constraints::Optional < Athena::Validator::Constraints::Existence
  # :inherit:
  def validated_by : NoReturn
    raise "BUG: #{self} cannot be validated"
  end
end
