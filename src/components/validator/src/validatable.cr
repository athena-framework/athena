# When included, denotes that a type (class or struct) can be validated via `Athena::Validator`.
#
# ### Example
#
# ```
# class Example
#   include AVD::Validatable
#
#   def initialize(@name : String); end
#
#   @[Assert::NotBlank]
#   property name : String
# end
#
# AVD.validator.validate Example.new("Jim")
# ```
module Athena::Validator::Validatable
  # :nodoc:
  module Class; end

  macro included
    extend AVD::Validatable::Class

    macro inherited
      include AVD::Validatable
    end

    {% unless @type.abstract? %}
      class_getter validation_class_metadata : AVD::Metadata::ClassMetadata(self) { AVD::Metadata::ClassMetadata(self).build }
    {% end %}
  end
end
