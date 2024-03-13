One of the benefits of using the Athena Framework is testing is considered a first class citizen.
Both the framework and the components themselves provides testing utilities to help ensure your code is working as expected.

## TestCase

At the core is the [Athena::Spec](/Spec) component, with [ASPEC::TestCase](/Spec/TestCase) being the primary type.
`ASPEC::TestCase` provides an alternative DSL for creating tests compliant with the stdlib's [Spec](https://crystal-lang.org/api/Spec.html) module.

NOTE: `ASPEC::TestCase` is _NOT_ a standalone testing framework, but is fully intended to be mixed with standard `describe`, `it`, and/or `pending` blocks depending on which approach makes the most sense for what is being tested.

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

TIP: The [ASPEC::TestCase::DataProvider](/Spec/TestCase/DataProvider) and [ASPEC::TestCase::TestWith](/Spec/TestCase/TestWith) annotations can make testing similar code with different inputs super easy!

## Testing Services

Testing a type/service is best done in isolation, using mocked versions of its dependencies to ensure that specific type is working as expected.
In most cases this can be as simple as defining a private class that includes/implements an interface along with additional inputs for asserting it was called as expected.
In other cases, the related component may provide these out of the box, such as:

* [AED::Spec::TracableEventDispatcher](/EventDispatcher/Spec/TracableEventDispatcher) For testing types that depend upon a [AED::EventDispatcherInterface](/EventDispatcher/EventDispatcherInterface)
* [ACLK::Spec::MockClock](/Clock/Spec/MockClock) For testing time sensitive types
* [AVD::Spec::FailingConstraint](/Validator/Spec/FailingConstraint) For testing invalid constraint related logic

Checkout the `Spec` namespace of each component in the [API Reference](../api_reference.md) for more examples.

## Testing Controllers

While testing a service in isolation is a good starting point; it does not make the most sense for all types of services.
A perfect example of this are [ATH::Controller](/Framework/Controller)s.
Controllers are best tested in conjunction with the various moving parts that make them function.

To make this as easy as possible, the framework provides [ATH::Spec::APITestCase](/Framework/Spec/APITestCase) and provides many helpful `HTTP` related [expectations](/Framework/SpecExpectations/HTTP).

```crystal
require "athena"
require "athena/spec"

class ExampleController < ATH::Controller
  @[ATHA::QueryParam("negative")]
  @[ARTA::Get("/add/{value1}/{value2}")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end
end

struct ExampleControllerTest < ATH::Spec::APITestCase
  def test_add_positive : Nil
    self.get("/add/5/3").body.should eq "8"
  end

  def test_add_negative : Nil
    self.get("/add/5/3?negative=true").body.should eq "-8"
  end
end

# Run all test case tests.
ASPEC.run_all
```

## Testing Commands

Similar to controllers, [commands](./commands.md) also have additional moving parts that need to accounted for when testing.
The [ACON::Spec::CommandTester](/Console/Spec/CommandTester) type can be used to simplify this:

```crystal
describe AddCommand do
  describe "#execute" do
    it "without negative option" do
      tester = ACON::Spec::CommandTester.new AddCommand.new
      tester.execute value1: 10, value2: 7
      tester.display.should eq "The sum of the values is: 17\n"
    end

    it "with negative option" do
      tester = ACON::Spec::CommandTester.new AddCommand.new
      tester.execute value1: -10, value2: 5, "--negative": nil
      tester.display.should eq "The sum of the values is: 5\n"
    end
  end
end
```
