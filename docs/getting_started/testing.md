Many Athena components include a `Spec` module that includes common/helpful testing utilities/types for testing that specific component. The framework itself defines some of its own testing types, mainly to allow for easily integration testing [ATH::Controller][]s via [ATH::Spec::APITestCase][] and also provides many helpful `HTTP` related [expectations][ATH::Spec::Expectations::HTTP].

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
