# Convenience alias to make referencing `Athena::Spec` types easier.
alias ASPEC = Athena::Spec

require "./methods"
require "./test_case"

# A set of common [Spec](https://crystal-lang.org/api/Spec.html) compliant testing utilities/types.
#
# ## Getting Started
#
# Unlike the other components, this one requires being manually installed, even if it is being used within the framework.
# This is due to there not being a way for a library to define development dependencies for the project that it is a dependency of.
#
# First add the component as a development dependency:
#
# ```yaml
# development_dependencies:
#   athena-spec:
#     github: athena-framework/spec
#     version: ~> 0.3.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-spec"` within your `spec/spec_helper.cr` file.
# From here you can create some `ASPEC::TestCase`s, or make use of the provided `ASPEC::Methods`.
#
# If using the component with the framework, also checkout the [manual](../architecture/spec.md) for some additional information on how it is integrated.
module Athena::Spec
  VERSION = "0.3.6"

  # Runs all `ASPEC::TestCase`s.
  #
  # Is equivalent to manually calling `.run` on each test case.
  def self.run_all : Nil
    {% for unit_test in ASPEC::TestCase.all_subclasses.reject { |tc| tc.abstract? || tc.annotation(ASPEC::TestCase::Skip) } %}
      {{unit_test.id}}.run
    {% end %}
  end
end
