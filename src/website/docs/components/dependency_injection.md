Athena utilizes the [Dependency Injection (DI)][Athena::DependencyInjection] component in order to provide a service container layer. DI allows controllers/other services to be decoupled from specific implementations. This also makes testing easier as test implementations of the dependencies can be used.

In Athena, most everything is a service that belongs to the container, which is unique to each request. The major benefit of this is it allows various types to be shared amongst the application without having them bleed state between requests. This section is _NOT_ an in-depth guide on what DI is, or all the features the DI component has. It is instead going to focus on high level usage and implementation specifics on how it is used within Athena itself; such how to register services and use them within other types.

See the [API Docs][Athena::DependencyInjection] for more details.

## Basic Usage

A type (class or struct) can be registered as a service by applying the [ADI::Register][Athena::DependencyInjection::Register] annotation to it. Services can depend upon other services by creating an `initializer` method type to the other service.

```crystal
require "athena"

# Register an example service that provides a name string.
@[ADI::Register]
class NameProvider
  def name : String
    "World"
  end
end

# Register another service that depends on the previous service and provides a value.
@[ADI::Register]
class ValueProvider
  def initialize(@name_provider : NameProvider); end
  
  def value : String
    "Hello " + @name_provider.name
  end
end

# Register a service controller that depends upon the ValueProvider.
@[ADI::Register(public: true)]
class ExampleController < ATH::Controller
  def initialize(@value_provider : ValueProvider); end
  
  @[ATHA::Get("/")]
  def get_value : String
    @value_provider.value
  end
end

ATH.run

# GET / # => "Hello World"
```
