# Allows wrapping `AVD::Constraint`(s) to denote it as being optional within an `AVD::Constraints::Collection`.
# See [this][Athena::Validator::Constraints::Collection--required-and-optional-constraints] for more information.
#
# ```crystal
# class Post
#   include AVD::Validatable
#
#   def initialize(@content : String); end
#
#   @[Assert::Optional]
#   property content : String
# end
# ```
class Athena::Validator::Constraints::Optional < Athena::Validator::Constraints::Existence
  # :inherit:
  def validated_by : NoReturn
    raise "BUG: #{self} cannot be validated"
  end
end
