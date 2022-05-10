# Convenience alias to make referencing `Athena::Spec` types easier.
alias ASPEC = Athena::Spec

require "./methods"
require "./test_case"

# A set of common [Spec](https://crystal-lang.org/api/Spec.html) compliant testing utilities/types.
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/components/spec) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# development_dependencies:
#   athena-spec:
#     github: athena-framework/spec
#     version: ~> 0.3.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-spec"` within your `spec/spec_helper.cr` file.
#
# From here you can create some `ASPEC::TestCase`s, or make use of the provided `ASPEC::Methods`.
module Athena::Spec
  VERSION = "0.3.0"

  # Runs all `ASPEC::TestCase`s.
  #
  # Is equivalent to manually calling `.run` on each test case.
  def self.run_all : Nil
    {% for unit_test in ASPEC::TestCase.all_subclasses.reject &.abstract? %}
      {{unit_test.id}}.run
    {% end %}
  end
end
