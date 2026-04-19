# Convenience alias to make referencing `Athena::Spec` types easier.
alias ASPEC = Athena::Spec

require "json"
require "./methods"
require "./test_case"

# A set of common [Spec](https://crystal-lang.org/api/Spec.html) compliant testing utilities/types.
module Athena::Spec
  VERSION = "0.4.2"

  # Asserts a *condition*, raising *message* if it is falsey.
  # This is primarily intended to be used with `ASPEC::Methods.assert_compiles` to assert state that exists at compile time.
  # An example of this is how internally Athena's specs do something like this to assert aspects of wired up services are correct:
  #
  # ```
  # ASPEC::Methods.assert_compiles <<-'CR'
  #   require "../spec_helper"
  #
  #   @[ADI::Register(public: true)]
  #   record MyService
  #
  #   macro finished
  #     macro finished
  #       \{%
  #         service = ADI::ServiceContainer::SERVICE_HASH["my_service"]
  #       %}
  #       ASPEC.compile_time_assert(\{{ service["public"] == true }}, "Expected service to be public")
  #     end
  #   end
  # CR
  # ```
  macro compile_time_assert(condition, message = "Compile-time assertion failed")
    {% condition.raise message unless condition %}
  end

  # Runs all `ASPEC::TestCase`s.
  #
  # Is equivalent to manually calling `.run` on each test case.
  def self.run_all : Nil
    # `#uniq` is to work around https://github.com/crystal-lang/crystal/issues/15793.
    {% for unit_test in ASPEC::TestCase.all_subclasses.reject { |tc| tc.abstract? || tc.annotation(ASPEC::TestCase::Skip) }.uniq %}
      ::{{unit_test.id}}.run
    {% end %}
  end
end
