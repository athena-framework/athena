The `Athena::Spec` component provides common/helpful [Spec](https://crystal-lang.org/api/Spec.html) compliant testing utilities.

NOTE: This component is _NOT_ a standalone testing framework, but is fully intended to be mixed with standard `describe`, `it`, and/or `pending` blocks depending on which approach makes the most sense for what is being tested.

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-spec:
    github: athena-framework/spec
    version: ~> 0.4.0
```

## Usage

A core focus of this component is allowing for a more classic unit testing approach that makes it easy to share/reduce test code duplication.
[ASPEC::TestCase][] being the core type of this.

The primary benefit of this approach is that logic is more easily shared/reused as compared to the normal block based approach.
I.e. a component can provide a base test case type that can be inherited from, a few methods implemented, and tada.
For example, [AVD::Spec::ConstraintValidatorTestCase](/Validator/Spec/ConstraintValidatorTestCase).

```crystal
struct ExampleSpec < ASPEC::TestCase
  def test_add : Nil
    (1 + 2).should eq 3
  end
end
```

TIP: The [ASPEC::TestCase::DataProvider][] and [ASPEC::TestCase::TestWith][] annotations can make testing similar code with different inputs super easy!
