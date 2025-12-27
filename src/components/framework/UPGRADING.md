# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.22.0

### Change how the `ATH::Action` is accessed

The `ATH::Request#action` getter used to access the matched `ATH::Action` instance has been removed.
The action is now stored within the request's attributes as `"_action"` and must be accessed via:
```crystal
request.attributes.get("_action", ATH::ActionBase)
````

`#get?` may be used in place of `#action?` if it's not guaranteed the action exists.

## Upgrade to 0.20.0

### Change how query parameters are represented

The `ATHA::QueryParam` annotation applied to the controller action is replaced with the `ATHA::MapQueryParameter` annotation applied directly to the parameter.

Before:

```crystal
class ExampleController < ATH::Controller
  @[ARTA::Get("/")]
  @[ATHA::QueryParam("page")]
  def index(page : Int32) : Int32
    page
  end
end
```

After:

```crystal
class ExampleController < ATH::Controller
  @[ARTA::Get("/")]
  def index(@[ATHA::MapQueryParameter] page : Int32) : Int32
    page
  end
end
```

See the [API Docs](https://athenaframework.org/Framework/Controller/ValueResolvers/QueryParameter/#Athena::Framework::Controller::ValueResolvers::QueryParameter) for more information.

### Change how request parameters are handled

The `ATHA::RequestParam` annotation that allowed mapping `x-www-form-urlencoded` form data within the request body to particular controller action parameters has been removed in favor of `ATHR::RequestBody`, which now supports deserializing form data request bodies into a DTO type.

Before:

```crystal
class ExampleController < ATH::Controller
  @[ARTA::Post("/login")]
  @[ATHA::RequestParam("username")]
  @[ATHA::RequestParam("password")]
  def login(username : String, password : String) : Nil
    # ...
  end
end
```

After:

```crystal
record LoginDTO, username : String, password : String do
  include URI::Params::Serializable
end

class ExampleController < ATH::Controller
  @[ARTA::Post("/login")]
  def login(@[ATHA::MapRequestBody] login : LoginDTO) : Nil
    # ...
  end
end
```

This provides better consistency and additional features such as adding validation constraints to the request parameters.

### Normalization of Exception types

The namespace exception types live in has changed from `ATH::Exceptions` to `ATH::Exception`.
Any usages of `framework` exception types will need to be updated.

If using a `rescue` statement with a parent exception type, either from the `framework` component or Crystal stdlib, double check it to ensure it'll still rescue what you are expecting it will.

### `ATHR::Interface.configuration` scoping

Previously if you had a value resolver using the `configuration` macro:

```cr
struct Multiply
  include ATHR::Interface

  configuration This

  # ...
end
```

The `This` configuration would be scoped to the `Multiply` namespace, i.e. `@[Multiply::This]`.
Scoping is now handled separately, meaning the same resolver could define multiple configurations to an entirely different namespace.
If you wish to retain the same behavior, provide the FQN to the `configuration` macro: `configuration Multiply::This`.
If you wish to move the configuration to another namespace, prefix the FQN with `::`: `configuration ::MyApp::Annotations::Multiply`.

## Upgrade to 0.19.0

### Change how framework features are configured

This change is a pretty fundamental change and cannot really be easily captured in this upgrading guide. Instead, take a moment to review the updated [Configuration](https://athenaframework.org/getting_started/configuration/) section in the getting started guide.

At a high level, the `.configure` calls have been replaced with `ATH.configure` that handles both configuration and parameters.
