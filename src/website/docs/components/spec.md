Athena strongly suggests following the [SOLID](https://en.wikipedia.org/wiki/SOLID) design principles;
especially the [Dependency inversion principle](https://en.wikipedia.org/wiki/Dependency_inversion_principle) in order to create types that are easy to test. See the [Dependency Injection](../components/dependency_injection.md) component for a more detailed look.

If these principles are followed then any controller/service can easily be unit tested on their own as you would any Crystal type, possibly utilizing [ASPEC::TestCase][Athena::Spec::TestCase] to provide helpful abstractions around common testing/helper logic for sets of common types.

However, Athena also comes bundled with [ATH::Spec::APITestCase][Athena::Framework::Spec::APITestCase] to allow for easily creating integration tests for [ATH::Controller][Athena::Framework::Controller]s; which is the more ideal way to test a controller.

```crystal
require "athena"
require "athena/spec"

class ExampleController < ATH::Controller
  @[ATHA::QueryParam("negative")]
  @[ATHA::Get("/add/:value1/:value2")]
  def add(value1 : Int32, value2 : Int32, negative : Bool = false) : Int32
    sum = value1 + value2
    negative ? -sum : sum
  end
end

struct ExampleControllerTest < ATH::Spec::APITestCase
  def test_add_positive : Nil
    self.request("GET", "/add/5/3").body.should eq "8"
  end

  def test_add_negative : Nil
    self.request("GET", "/add/5/3?negative=true").body.should eq "-8"
  end
end

# Run all test case tests.
ASPEC.run_all
```

Integration tests allow testing the full system, including event listeners, param converters, etc at once.
These tests do not utilize an [HTTP::Server](https://crystal-lang.org/api/HTTP/Server.html) which results in more performant specs.
