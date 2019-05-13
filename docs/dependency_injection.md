# Dependency Injection

Athena's Dependency Injection (DI) module adds a service container layer to your project.  This allows a project to share useful objects, aka services, throughout the project.  These objects live in a special class called the Service Container (SC).  Object instances can be retrieved from the container, or even injected directly into classes as a form of constructor DI.

By default, the SC is added to the main fiber of the project.  This allows the SC to be retrieved anywhere within the project.  The `Athena::DI.get_container` method will return the SC for the current fiber.  Since the SC is defined on fibers, it allows for each fiber to have its own SC.  This can be useful for web frameworks as each request would have its own SC scoped to that request.  This however, is up to the each project to implement. 

## Registering Services

Before a service can be used, it must be registered with the SC.  This is done by annotating a class/struct with `@[Athena::DI::Register]` annotation.  The type must also inherit from the proper parent, `Athena::DI::ClassService` and `Athena::DI::StructService` respectively.  The behavior of the service depends on whether it is a `struct` or a `class`. 

A `struct` service, when injected into a class, or retrieved from the SC, will be a copy of the one in the SC.  This means changes made to it in one class/place will _NOT_ be reflected in other classes/places.

A `class` service on the other hand will be a reference to the one in the SC.  This allows it to share state between classes/places within the project.

**NOTE:** In the future the parent `class`/`struct` will be changed to `include Athena::DI::Service`.  Currently there just isn't another way to get an array of services until [this issue](<https://github.com/crystal-lang/crystal/pull/7648>) is merged.

```crystal
require "athena/di"

@[Athena::DI::Register]
class Store < Athena::DI::ClassService
  property name : String = "Jim"
end
```

### With Arguments

If a class has an initializer, the arguments to use can be specified within the annotation.

```crystal
require "athena/di"

# The arguments are defined in the same order as the initialize method.
@[Athena::DI::Register("GOOGLE", "Google")]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end
```

### Custom Service Name

By default the name of the service would be the name of the type, snake-cased.  I.e. `feed_partner`.  The `Register` annotation accepts a `name` field that allows the name of the service to be customized.  

```crystal
require "athena/di"

@[Athena::DI::Register("GOOGLE", "Google", name: "google")]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end
```

This would register a service named `google` based on the  class `FeedPartner`.  

Multiple `Register` annotations can be added to a type.  This combined with the `name` field can be used to register multiple services based on the same base class, but with different arguments.

```crystal
require "athena/di"

@[Athena::DI::Register("GOOGLE", "Google", name: "google")]
@[Athena::DI::Register("FACEBOOK", "Facebook", name: "facebook")]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end
```

### Tagging

Services can also be assigned tags.  These services can then be retrieved, by tag name, from the SC.

```crystal
require "athena/di"

@[Athena::DI::Register("GOOGLE", "Google", name: "google", tags: ["feed_partner"])]
@[Athena::DI::Register("FACEBOOK", "Facebook", name: "facebook", tags: ["feed_partner"])]
struct FeedPartner < Athena::DI::StructService
  getter id : String
  getter name : String

  def initialize(@id : String, @name : String); end
end
```

## Retrieving Services

Once services have been registered they are available within the SC.

### Get

The `get` method can be used to retrieve a service by name from the container.

```crystal
# Assuming we've registered the services above
store = Athena::DI.get_container.get("store")
store.name # => "Jim"
```

The other variant of the `get` command accepts a `Athena::DI::Service.class` argument and will return all services of that type.

```crystal
# Assuming we've registered the services above
feed_partners = Athena::DI.get FeedPartner
feed_partners # => [FeedPartner(@id="GOOGLE", @name="Google"), FeedPartner(@id="FACEBOOK", @name="Facebook")]
```

### Tagged

The `tagged` method can be used to retrieve an array of services that have a specific tag.

```crystal
# Assuming we've registered the services above
feed_partners = Athena::DI.get_container.tagged "feed_partner"
feed_partners # => [FeedPartner(@id="GOOGLE", @name="Google"), FeedPartner(@id="FACEBOOK", @name="Facebook")]
```

## Auto Injection

Services can also be injected directly into a class.

Following along from our earlier example, if we wanted to inject the `Store` class into another object we would first define an `initialize` method with `Store` as the type restriction.  Next, `include Athena::DI::Injectable` to tell `Athena::DI` that this class should be auto injected.

```crystal
require "athena/di"

class SomeClass
  include Athena::DI::Injectable

  def initialize(@store : Store); end
end

some_class = SomeClass.new
```

Thats it.  This class will then have access to a shared `Store` object.  Any changes made to it within `SomeClass` would be reflected in other classes it was also injected into.  

Service lookup is based on the type of the restriction and the name of the variable.

```crystal
require "athena/di"

class SomeClass
  include Athena::DI::Injectable

  def initialize(@partners : FeedPartner); end
end

# This would fail with the error 
# "Could not resolve a service with type 'FeedPartner' and name of 'partners'."
# since it was not able to resolve the type and name combo into a singular service.
some_class = SomeClass.new
```

```crystal
require "athena/di"

class SomeClass
  include Athena::DI::Injectable

  def initialize(@google : FeedPartner); end
end

# This would inject the service of type `FeedPartner` with the name `google`.
some_class = SomeClass.new
```

If a class's `initialize` method has other arguments that are not part of the SC, they can be specified by name.

```crystal
require "athena/di"

class SomeClass
  include Athena::DI::Injectable

  def initialize(@store : Store, @id : String); end
end

# The store ivar would be auto injected,  
# while the id ivar is supplied when the class is newd up.
some_class = SomeClass.new id: "FOO"
```

The auto injected instance variable can also be overridden.  

```crystal
require "athena/di"

class SomeClass
  include Athena::DI::Injectable

  def initialize(@store : Store, @id : String); end
end

some_other_store = ...
some_class = SomeClass.new id: "FOO", store: some_other_store
```

This is useful as `Store` could be a parent class that multiple types of stores inherit from.  Alternatively, the mock store could inherit from the actual store, but mocking out data within the mock.  This is useful for tests as it allows the dependencies of a class to not interfere with the testing of that specific class.
