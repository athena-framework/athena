# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.4.1

### Single implementation aliases are now explicit

Previously if you had a service that implemented an interface (module), that interface would auto resolve to that service if there was only the one implementation.
This implicit aliasing of the interface was removed and now requires an explicit aliasing.

Before:
```crystal
module SomeInterface; end

@[ADI::Register]
class Foo
  include SomeInterface
end

@[ADI::Register(public: true)]
record Bar, a : SomeInterface
```

After:
```crystal
module SomeInterface; end

@[ADI::Register]
@[ADI::AsAlias]
class Foo
  include SomeInterface
end

@[ADI::Register(public: true)]
record Bar, a : SomeInterface
```

If the service only implements a single interface, you just need to apply the [`@[ADI::AsAlias]`](https://athenaframework.org/DependencyInjection/AsAlias/) annotation to the service.
If it implements more than one interface, you'll need an annotation for each one.
See the API docs for more information on how to use the annotation.

## Upgrade to 0.4.0

_The component went through a large internal refactor as part of this release. Please create an issue or PR if you find a breaking change not captured here._

### Remove built-in integrations

The built-in `Clock`, `Console`, and `EventDispatcher` integrations have been removed. The Athena Framework is now responsible for the integration of all the components. If you were using one of these components with the `DependencyInjection` component outside of the framework, you will need to manually handle wiring things up.

### Remove `ADI.auto_configure`

The `ADI.auto_configure` macro has been replaced with the `ADI::Autoconfigure` annotation.

Before:
```crystal
module ConfigInterface; end

ADI.auto_configure ConfigInterface, {tags: ["config"]}
```

After:
```crystal
@[ADI::Autoconfigure(tags: ["config"])]
module ConfigInterface; end
```

See the [API Docs](https://athenaframework.org/DependencyInjection/Autoconfigure/) for more information.

### Remove `alias` field of `ADI::Register`

Service aliases are no longer defined via the `alias` field as part of the `ADI::Register` annotation. Instead, they are now handled via the new `ADI::AsAlias` annotation.

Before:
```crystal
module TransformerInterface
  abstract def transform(value : String) : String
end

@[ADI::Register(alias: TransformerInterface)]
struct ShoutTransformer
  include TransformerInterface

  # ...
end
```

After:
```crystal
module TransformerInterface
  abstract def transform(value : String) : String
end

@[ADI::Register]
@[ADI::AsAlias(TransformerInterface)]
struct ShoutTransformer
  include TransformerInterface

  # ...
end
```

See the [API Docs](https://athenaframework.org/DependencyInjection/AsAlias/) for more information.
