##  Creating "good" Software

When creating an application, actually writing the code is often the easiest part. Designing a system that will be readable, maintainable, testable, and extensible on the other hand is a much more challenging task. The features of the Athena Framework encourage creating such software. However it does not do much good without also understanding the _why_ behind the way it is designed the way it is. Let's take a moment to explore how the features mentioned in the introduction can lead to "good" software design.

WARNING: As with anything in the software world, "good" software is subjective. The design decision/suggestions on this page are intended to be educational and provide "best practices" guidelines. They are _NOT_ the only way to use the framework nor prescriptive. Do whatever makes the most sense for your project.

### SOLID Principles

The [SOLID](https://en.wikipedia.org/wiki/SOLID) principles are applicable to any Object Oriented Programming (OOP) language. They play a big part in the underlying architecture of the Athena Framework, and the overall ecosystem of Athena itself. There are plenty of resources online to learn more about all of the principles, but this section will focus on that of the _Dependency Inversion_ and _Single Responsibility_ principles and how an [Inversion of Control (IoC)](https://en.wikipedia.org/wiki/Inversion_of_control) service container orchestrates it all via [dependency injection](https://en.wikipedia.org/wiki/Dependency_injection).

#### Single Responsibility

Just as the name implies, this principle suggests that each type should have only a single primary purpose. Having types with specialized focuses has various benefits including:

* Easier to test
* Less coupling due to lower amount of dependencies it requires
* Easier to read and search for

A more concrete example of this could be say there is a class representing an article:

```crystal
class Article
  property title : String
  property author : String
  property body : String

  def initialize(@title : String, @author : String, @body : String); end

  def includes_word?(word : String) : Bool
    @body.includes? word
  end

  # ...
end
```

This type currently only has a single purpose which is representing an article. It also exposes some helper methods related to querying information about each article which are also valid under this principle. However, if a new method was added to persist the article to some location, the class would now no longer have just one purpose, thus violating the single responsibility principle.

In this example, it would be better to add _another_ type, say `ArticlePersister` to handle this functionality:

```crystal
@[ADI::Register]
class ArticlePersister
  def persist(article : Article) : Nil
    # ...
  end
end
```

##### Services

A sharp eye will notice this type was created with the [ADI::Register](/DependencyInjection/Register/) annotation applied to it. This registers the type as a service, which is essentially just a useful object that could be used by other services. Not all types are services though, such as the `Article` type. This is because it only stores data within the domain of the application and does not provide any useful functionality on its own. More on this topic in the [dependency injection](#dependency-injection) section.

#### Dependency Inversion

This principle states that code should "Depend upon abstractions, [not] concretions." In other words, services should depend upon interfaces instead of concrete types. This not only makes the depending services more flexible since different implementations of the interface could be used, but also makes testing easier since mock implementations could also be used. In Crystal, an interface is nothing more than a module with abstract defs that can be included within another type in order to force the including type to define its methods.The example from the previous principle can be used to demonstrate.

The `ArticlePersister` can be used to persist an article. For example say there is another service in which an article should be persisted. This could be a controller action, a console command, some sort of async consumer, etc. The easiest way to handle persisting of the article would be to do something like:

```crystal
@[ADI::Register]
class MyService
  def execute
    article = # ...
    persister = ArticlePersister.new

    persister.persist article
  end
end
```

However this has some problems since it tightly couples `MyService` to the `ArticlePersister` service. Not super ideal.

```crystal
def initialize
  @persister = ArticlePersister.new
end
```

Moving the persister into an instance variable created within the constructor is a bit better but also suffers from the same issue. The ideal solution here would be to provide an `ArticlePersister` instance to `MyService` when it is instantiated:

```crystal
def initialize(
  @persister : ArticlePersister
); end
```

The same behavior as before can also be retained, even when using this new pattern. This will use the provided instance, or fall back on a default implementation if no custom instance is provided:

```crystal
def initialize(
  persister : ArticlePersister? = nil
)
  @persister = persister || ArticlePersister.new
end
```

Both of these latter two examples remove the tight coupling between the two services. However there is still one thing that is less than ideal. It should be possible to persist an article in multiple places. Meaning it needs to allow for more than one implementation of `ArticlePersister` that handles different locations, such as one for a database and another for the local filesystem. The best way to handle this would be to create an interface module for this type:

```crystal
module ArticlePersisterInterface
  abstract def persist(article : Article) : Nil
end
```

From here the constructor of `MyService` should be updated to use it:

```crystal
def initialize(
  @persister : ArticlePersisterInterface
); end
```

Also being sure to include the interface in our service:

```crystal
@[ADI::Register]
class ArticlePersister
  include ArticlePersisterInterface

  def persist(article : Article) : Nil
    # ...
  end
end
```

While this is a bit of extra boilerplate, it is an incredibly powerful pattern. It enables `MyService` to persist an article to anywhere, depending on what implementation instance it is instantiated with. The same pattern can be extended to make testing the service much easier. A mock implementation of `ArticlePersisterInterface` can be used to assert `MyService` calls with the proper arguments without testing more than is required.

### Flexibility

Athena Framework is very flexible in that it is able to support both simple and complex use cases by adapting to the needs of the application without getting in the way of customizations the user wants to make. This is accomplished by providing all the components to the user, but not requiring they be used. If an application does not need to validate anything, the [Athena::Validator](/Validator/) component can just be ignored. But if the need ever arises it is there and well integrated into the framework.

#### Dependency Injection

Athena Framework includes an IoC Service Container that manages services automatically. Any service, or a useful type, annotated with [ADI::Register](/DependencyInjection/Register/), can be used in another service by defining a constructor typed to the desired service. For example:

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
@[ADI::Register]
class ExampleController < ATH::Controller
  def initialize(@value_provider : ValueProvider); end

  @[ARTA::Get("/")]
  def get_value : String
    @value_provider.value
  end
end

ATH.run

# GET / # => "Hello World"
```

It is worth noting again that while dependency injection is a big part of the framework, it is not necessarily required to fully understand it in order to use the framework, but like the other components, it is there if needed. Checkout [ADI::Register](/DependencyInjection/Register/), especially the [aliasing services](/DependencyInjection/Register/#Athena::DependencyInjection::Register--aliasing-services) section.

Athena Framework is almost fully overridable/customizable in part since it embraces dependency injection. Want to globally customize how errors are rendered? Create a service implementing [ATH::ErrorRendererInterface](/Framework/ErrorRendererInterface/) and make it an alias of the interface:

```crystal
@[ADI::Register(alias: ATH::ErrorRendererInterface)]
class MyCustomErrorRenderer
  include Athena::Framework::ErrorRendererInterface

  # :inherit:
  def render(exception : ::Exception) : ATH::Response
    ATH::Response.new ...
  end
end
```

Athena Framework will pick this up and use it instead of the built in version without any other required configuration changes. The same concept applies to many different features within the framework that have their own interface/default implementation.

#### Middleware

Unlike other frameworks, Athena Framework leverages event based middleware instead of a pipeline based approach. This enables a lot of flexibility in that there is nothing extra that needs to be done to register the listener other than creating a service for it:

```crystal
@[ADI::Register]
class CustomListener
  include AED::EventListenerInterface

  @[AEDA::AsEventListener]
  def on_response(event : ATH::Events::Response) : Nil
    event.response.headers["FOO"] = "BAR"
  end
end
```

Similarly, the framework itself is implemented using the same features available to the users. Thus it is very easy to run specific listeners before/after the built-in ones if so desired.

TIP: Check out the `debug:event-dispatcher` command for an easy way to see all the listeners and the order in which they are executed.

### Annotations

One of the more unique aspects of Athena Framework, and the Athena ecosystem, is its use of [annotations](https://crystal-lang.org/reference/syntax_and_semantics/annotations/index.html) as a means of configuring the framework. While not everyone may like their syntax, the benefits they provide are undeniable. The main benefit being they keep the code close to where it is used. The route of a controller action is declared directly above the method that handles it and not in some other file. Metadata associated with a specific service/route is also right there with the type itself.

#### Point of Extension

A common way to do certain things in other frameworks is the use of macro DSLs specific to each framework. While it can work well, it makes it harder to expand upon/customize. Given annotations are a core Crystal language construct, there nothing special needed to access the annotations themselves. This can be especially useful for third party code to have a tighter integration while also being totally agnostic of what framework the code is even used in.

#### User Defined Annotations

One of the most powerful features Athena Framework offers is that of custom user defined annotations which provide almost an infinite amount of use cases. These annotations could be applied to controller classes and/or controller actions to expose additional information to other services, such as event listeners or [ATHR::Interfaces](/Framework/Controller/ValueResolvers/Interface/) to customize their behavior on a case by case basis.

```crystal
require "athena"

# Define our configuration annotation with an optional `name` argument.
# A default value can also be provided, or made not nilable to be considered required.
ACF.configuration_annotation MyAnnotation, name : String? = nil

# Define and register our listener that will do something based on our annotation.
@[ADI::Register]
class MyAnnotationListener
  include AED::EventListenerInterface

  @[AEDA::AsEventListener]
  def on_view(event : ATH::Events::View) : Nil
    # Represents all custom annotations applied to the current ATH::Action.
    ann_configs = event.request.action.annotation_configurations

    # Check if this action has the annotation
    unless ann_configs.has? MyAnnotation
      # Do something based on presence/absence of it.
      # Would be executed for `ExampleController#one` since it does not have the annotation applied.
    end

    my_ann = ann_configs[MyAnnotation]

    # Access data off the annotation.
    if my_ann.name == "Fred"
      # Do something if the provided name is/is not some value.
      # Would be executed for `ExampleController#two` since it has the annotation applied, and name value equal to "Fred".
    end
  end
end

class ExampleController < ATH::Controller
  @[ARTA::Get("one")]
  def one : Int32
    1
  end

  @[ARTA::Get("two")]
  @[MyAnnotation(name: "Fred")]
  def two : Int32
    2
  end
end

ATH.run
```

## Primary Use Cases

While the components that make up Athena Framework can be used within a wide range of applications, the framework itself is best suited for a few main types, including HTTP REST APIs, CLI Applications, or a combination of both. Since both types of entry points leverage dependency injection, services can be used in both contexts, allowing the majority of code to be reused.

### HTTP REST API

At its core, Athena Framework is a MVC web application framework. It can be used to serve any kind of content, but best lends itself to creating RESTful JSON APIs due to the features explained in the previous section, as well as due its native JSON support:

* Objects returned from the controller are JSON serialized by default
* Native support for both [ASR::Serializable](/Serializer/Serializable) and [JSON::Serializable](https://crystal-lang.org/api/JSON/Serializable.html)
* Native support for DTOs to deserialize and validate, see [ATHR::RequestBody](/Framework/Controller/ValueResolvers/RequestBody/)

```crystal
require "athena"

struct UserCreate
  include AVD::Validatable
  include JSON::Serializable

  @[Assert::NotBlank]
  @[Assert::Email(:html5)]
  getter email : String

  # ...
end

class UserController < ATH::Controller
  @[ARTA::Post("/user")]
  @[ATHA::View(status: :created)]
  def new_user(
    @[ATHR::RequestBody::Extract]
    user_create : UserCreate
  ) : UserCreate
    # Use the provided UserCreate instance to create an actual User DB record.
    # For purposes of this example, just return the instance.

    user_create
  end
end

ATH.run

# POST /user body: {"email":"athenaframework.org"} # =>
# {
#   "code": 422,
#   "message": "Validation failed",
#   "errors": [
#     {
#       "property": "email",
#       "message": "This value is not a valid email address.",
#       "code": "ad9d877d-9ad1-4dd7-b77b-e419934e5910"
#     }
#   ]
# }

# POST /user body: {"email":"contact@athenaframework.org"} # => {"email":"contact@athenaframework.org"}
```

### CLI Applications

Athena Framework can also be used to build CLI based applications. These could either be used directly by the end user, used for internal administrative tasks, or invoked on a schedule via `cron` or something similar.

```crystal
@[ACONA::AsCommand("app:create-user")]
@[ADI::Register]
class CreateUserCommand < ACON::Command
  protected def configure : Nil
    # ...
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # Implement all the business logic here.

    # Indicates the command executed successfully.
    Status::SUCCESS
  end
end
```

```shell
$ ./bin/console
Athena 0.18.0

Usage:
  command [options] [arguments]

Options:
  -h, --help            Display help for the given command. When no command is given display help for the list command
  -q, --quiet           Do not output any message
  -V, --version         Display this application version
      --ansi|--no-ansi  Force (or disable --no-ansi) ANSI output
  -n, --no-interaction  Do not ask any interactive question
  -v|vv|vvv, --verbose  Increase the verbosity of messages: 1 for normal output, 2 for more verbose output and 3 for debug

Available commands:
  help                    Display help for a command
  list                    List commands
 app
  app:create-user
 debug
  debug:event-dispatcher  Display configured listeners for an application
  debug:router            Display current routes for an application
  debug:router:match      Simulate a path match to see which route, if any, would handle it
```

Checkout the [Console](/Console/) component for more information.
