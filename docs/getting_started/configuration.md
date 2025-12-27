Some features need to be configured;
either to enable/control how they work, or to customize the default functionality.

The [ATH.configure](/Framework/top_level/#Athena::Framework:configure(config)) macro is the primary entrypoint for configuring Athena Framework applications.
It is used in conjunction with the related [bundle schema](/Framework/Bundle/Schema/Cors/Defaults/) that defines the possible configuration properties:

```crystal
ATH.configure({
  framework: {
    cors: {
      enabled:  true,
      defaults: {
        allow_credentials: true,
        allow_origin: ["https://app.example.com"],
        expose_headers: ["X-Transaction-ID X-Some-Custom-Header"],
      },
    },
  },
})
```

In this example we enable the [CORS Listener](/Framework/Listeners/CORS), as well as configure it to function as we desire.
However you may be wondering "how do I know what configuration properties are available?" or "what is that 'bundle schema' thing mentioned earlier?".
For that we need to introduce the concept of a `Bundle`.

## Bundles

It should be well known by now that the components that make up Athena's ecosystem are independent and usable outside of the Athena Framework itself.
However because they are made with the assumption that the entire framework will not be available, there has to be something that provides the tighter integration into the rest of the framework that makes it all work together so nicely.

Bundles in the Athena Framework provide the mechanism by which external code can be integrated into the rest of the framework.
This primarily involves wiring everything up via the [Athena::DependencyInjection](/DependencyInjection) component.
But it also ties back into the configuration theme by allowing the user to control _how_ things are wired up and/or function at runtime.

What makes the bundle concept so powerful and flexible is that it operates at the compile time level.
E.g. if feature(s) are disabled in the configuration, then the types related to those feature(s) will not be included in the resulting binary at all.
Similarly, the configuration values can be accessed/used as constructor arguments to the various services, something a runtime approach would not allow.

TODO: Expand upon bundle internals and how to create custom bundles.

### Schemas

Each bundle is responsible for defining a "schema" that represents the possible configuration properties that relate to the services provided by that bundle.
Each bundle also has a name that is used to namespace the configuration passed to `ATH.configure`.
From there, the keys maps to the downcase snakecased of the types found within the bundle's schema.
For example, the [Framework Bundle](/Framework/Bundle) used in the previous example, exposes `cors` and `format_listener` among others as part of its schema.

NOTE: Bundles and schemas are not something the average end user is going to need to define/manage themselves other than register/configure to fit their needs.

#### Validation

The compile time nature of bundles also extends to how their schemas are validated.
Bundles will raise a compile time error if the provided configuration values are invalid according to its schema.
For example:

```crystal
 10 | allow_credentials: 10,
                          ^
Error: Expected configuration value 'framework.cors.defaults.allow_credentials' to be a 'Bool', but got 'Int32'.
```

This also works for nested values:

```crystal
 10 | allow_origin:      [10, "https://app.example.com"] of String,
                           ^
Error: Expected configuration value 'framework.cors.defaults.allow_origin[0]' to be a 'String', but got 'Int32'.
```

Or if the schema defines a value that is not nilable nor has a default:

```crystal
 10 | property some_property : String
               ^------------
Error: Required configuration property 'framework.some_property : String' must be provided.
```

It can also call out unexpected keys:

```crystal
 10 | foo:      "bar",
                 ^
Error: Encountered unexpected property 'framework.cors.foo' with value '"bar"'.
```

Hash configuration values are unchecked so are best used for unstructured data.
If you have a fixed set of related configuration, consider using [object_of](/DependencyInjection/Extension/Schema/#Athena::DependencyInjection::Extension::Schema:object_of(name,*)).

#### Multi-Environment

In most cases, the configuration for each bundle is likely going to vary one environment to another.
Values that change machine to machine should ideally be leveraging environmental variables.
However, there are also cases where the underlying configuration should be different.
E.g. locally use an in-memory cache while using redis in other environments.

To handle this, `ATH.configure` may be called multiple times, with the last call taking priority.
The configuration is deep merged together as well, so only the configuration you wish to alter needs to be defined.
However hash/array/namedTuple values are not.
Normal compile time logic may be used to make these conditional as well.
E.g. basing things off `--release` or `--debug` flags vs the environment.

```crystal
ATH.configure({
  framework: {
    cors: {
      defaults: {
        allow_credentials: true,
        allow_origin:      ["https://app.example.com"],
        expose_headers:    ["X-Transaction-ID", "X-Debug-Header"],
      },
    },
  },
})

# Exclude the debug header in prod, but retain the other two configuration property values
{% if env(Athena::ENV_NAME) == "prod" %}
ATH.configure({
  framework: {
    cors: {
      defaults: {
        expose_headers:    ["X-Transaction-ID"],
      },
    },
  },
})
{% end %}

# Do this other thing if in a non-release build
{% unless flag? "release" %}
ATH.configure({...})
{% end %}
```

TIP: Consider abstracting the additional `ATH.configure` calls to their own files, and `require` them.
This way things stay pretty organized, without needing large conditional logic blocks.

## Parameters

Sometimes the same configuration value is used in several places within `ATH.configure`.
Instead of repeating it, you can define it as a "parameter", which represents reusable configuration values.
Parameters are intended for values that do not change between machines, and control the application's behavior, e.g. the sender of notification emails, what features are enabled, or other high level application level values.

Parameters should _NOT_ be used for values that rarely change, such as the max amount of items to return per page.
These types of values are better suited to being a [constant](https://crystal-lang.org/reference/syntax_and_semantics/constants.html) within the related type.
Similarly, infrastructure related values that change from one machine to another, e.g. development machine to production server, should be defined using environmental variables.

Parameters can be defined using the special top level `parameters` key within `ATH.configure`.

```crystal
ATH.configure({
  parameters: {
    # The parameter name is an arbitrary string,
    # but is suggested to use some sort of prefix to differentiate your parameters
    # from the built-in framework parameters, as well as other bundles.
    "app.admin_email": "admin@example.com",

    # Boolean param
    "app.enable_v2_protocol": true,

    # Collection param
    "app.supported_locales": ["en", "es", "de"],
  },
})
```

The parameter value may be any primitive type, including strings, bools, hashes, arrays, etc.
From here they can be used when configuring a bundle via enclosing the name of the parameter within `%`.
For example:

```crystal
ATH.configure({
  some_bundle: {
    email: "%app.admin_email%",
  },
})
```

TIP: Parameters may also be [injected](/DependencyInjection/Register/#Athena::DependencyInjection::Register--parameters) directly into services via their constructor.

## Custom Annotations

Athena integrates the [Athena::DependencyInjection](/DependencyInjection) component's ability to define custom annotation configurations.
This feature allows developers to define custom annotations, and the data that should be read off of them, then apply/access the annotations on [ATH::Controller](/Framework/Controller) and/or [ATH::Action](/Framework/Action)s.

This is a powerful feature that allows for almost limitless flexibility/customization.
Some ideas include: storing some value in the request attributes and raise an exception or invoke some external service; all based on the presence/absence of it, a value read off of it, or either/both of those in-conjunction with an external service.
For example:

```crystal
require "athena"

# Define our configuration annotation with an optional `name` argument.
# A default value can also be provided, or made not nilable to be considered required.
ADI.configuration_annotation MyAnnotation, name : String? = nil

# Define and register our listener that will do something based on our annotation.
@[ADI::Register]
class MyAnnotationListener
  @[AEDA::AsEventListener]
  def on_view(event : ATH::Events::View) : Nil
    # Represents all custom annotations applied to the current ATH::Action.
    ann_configs = event.request.attributes.get("_action", ATH::ActionBase).annotation_configurations

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

### Pagination

<!-- TODO: Move this to a cookbook/how-to type of page/section? -->

A good example use case for custom annotations is the creation of a `Paginated` annotation that can be applied to controller actions to have them be paginated via the listener. Generic pagination can be implemented via listening on the [view](./middleware.md#4-view-event) event which exposes the value returned via the related controller action.

```crystal

# Define our configuration annotation with the default pagination values.
# These values can be overridden on a per endpoint basis.
ADI.configuration_annotation Paginated, page : Int32 = 1, per_page : Int32 = 100, max_per_page : Int32 = 1000

# Define and register our listener that will handle paginating the response.
@[ADI::Register]
struct PaginationListener
  private PAGE_QUERY_PARAM     = "page"
  private PER_PAGE_QUERY_PARAM = "per_page"

  # Use a high priority to ensure future listeners are working with the paginated data
  @[AEDA::AsEventListener(priority: 255)]
  def on_view(event : ATH::Events::View) : Nil
    # Return if the endpoint is not paginated.
    return unless (pagination = event.request.attributes.get("_action", ATH::ActionBase).annotation_configurations[Paginated]?)

    # Return if the action result is not able to be paginated.
    return unless (action_result = event.action_result).is_a? Indexable

    request = event.request

    # Determine pagination values; first checking the request's query parameters,
    # using the default values in the `Paginated` object if not provided.
    page = request.query_params[PAGE_QUERY_PARAM]?.try &.to_i || pagination.page
    per_page = request.query_params[PER_PAGE_QUERY_PARAM]?.try &.to_i || pagination.per_page

    # Raise an exception if `per_page` is higher than the max.
    raise ATH::Exception::BadRequest.new "Query param 'per_page' should be '#{pagination.max_per_page}' or less." if per_page > pagination.max_per_page

    # Paginate the resulting data.
    # In the future a more robust pagination service could be injected
    # that could handle types other than `Indexable`, such as
    # ORM `Collection` objects.
    end_index = page * per_page
    start_index = end_index - per_page

    # Paginate and set the action's result.
    event.action_result = action_result[start_index...end_index]
  end
end

class ExampleController < ATH::Controller
  @[ARTA::Get("values")]
  @[Paginated(per_page: 2)]
  def get_values : Array(Int32)
    (1..10).to_a
  end
end

ATH.run

# GET /values # => [1, 2]
# GET /values?page=2 # => [3, 4]
# GET /values?per_page=3 # => [1, 2, 3]
# GET /values?per_page=3&page=2 # => [4, 5, 6]
```
