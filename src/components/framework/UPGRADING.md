# Upgrading

Documents the changes that may be required when upgrading to a newer component version.

## Upgrade to 0.23.0

### The Serializer component is optional

The framework no longer depends on the [Serializer](https://athenaframework.org/Serializer/) component.
Without it, the data returned from controller actions is serialized via `#to_json`, and `ATHR::RequestBody` deserializes JSON request bodies into `JSON::Serializable` types.
Applications that use `ASR::Serializable` types, serialization groups or versions, or inject `ASR::SerializerInterface` need to add the component to their `shard.yml` and register its [bundle](https://athenaframework.org/Serializer/Bundle/):

```crystal
require "athena"
require "athena-serializer/bundle"
```

The bundle registers the serializer as the `serializer` service, which was previously `athena_serializer_serializer`.

### The Validator component is optional

The framework no longer depends on the [Validator](https://athenaframework.org/Validator/) component.
Without it, `ATHR::RequestBody` does not validate the objects it resolves.
Applications that validate request bodies, query strings or uploaded files, inject `AVD::Validator::ValidatorInterface`, or define `AVD::ServiceConstraintValidator`s need to add the component to their `shard.yml` and register its [bundle](https://athenaframework.org/Validator/Bundle/):

```crystal
require "athena"
require "athena-validator/bundle"
```

If the bundle is not registered, it is a compile time error for an `ATHA::MapRequestBody` or `ATHA::MapQueryString` parameter's type to include `AVD::Validatable`, or for those annotations to set `validation_groups`, or `ATHA::MapUploadedFile` to set `constraints`.

The bundle registers the validator as the `validator` service, which was previously `athena_validator_validator_recursive_validator`.
`AVD::ServiceConstraintValidator`s are now tagged `validator.constraint_validator` instead of `athena.validator.constraint_validator`.

The validator parameter of `ATHR::RequestBody` is now optional, and comes last.

### The Console component is optional

The framework no longer depends on the [Console](https://athenaframework.org/Console/) component.
Applications that define console commands, or use `ATH.run_console`, need to add the component to their `shard.yml` and register its [bundle](https://athenaframework.org/Console/Bundle/):

```crystal
require "athena"
require "athena-console/bundle"
```

`ATH::Console::Application`, and its `athena_console_application` service, have been removed.
`ATH.run_console` now runs the application created via `ACON::Application.new("Athena", ATH::VERSION, ADI.container)`, which can also be used to create a customized application.
Commands are now tagged `console.command` instead of `athena.console.command`.

### The Clock and Negotiation components are optional

The framework no longer depends on the [Clock](https://athenaframework.org/Clock/) or [Negotiation](https://athenaframework.org/Negotiation/) components.
Applications that use either need to add it to their `shard.yml` and require it:

```crystal
require "athena"
require "athena-clock"
require "athena-negotiation"
```

### Framework services serialize through `ATH::Serializer::Interface`

`ATH::View::ViewHandler` and `ATHR::RequestBody` now depend on the new [ATH::Serializer::Interface](https://athenaframework.org/Framework/Serializer/Interface) instead of `ASR::SerializerInterface`.
The serializer is now an optional parameter.
If the Serializer bundle is registered, the [ATH::Serializer::ComponentSerializer](https://athenaframework.org/Framework/Serializer/ComponentSerializer) service implements it with the Serializer component, so applications using the default services do not need to change anything.
Code that constructs either type directly, such as in specs, needs to provide an `ATH::Serializer::Interface` instead:

Before:

```crystal
ATH::View::ViewHandler.new url_generator, ASR::Serializer.new, request_store, format_handlers
ATHR::RequestBody.new ASR::Serializer.new, validator, annotation_resolver
```

After:

```crystal
ATH::View::ViewHandler.new url_generator, request_store, format_handlers, ATH::Serializer::ComponentSerializer.new(ASR::Serializer.new)
ATHR::RequestBody.new annotation_resolver, ATH::Serializer::ComponentSerializer.new(ASR::Serializer.new), validator
```

### Exclusion strategies removed from `ATH::View::Context`

`ATH::View::Context#exclusion_strategies` and `ATH::View::Context#add_exclusion_strategy` have been removed.
Actions that need a custom exclusion strategy can serialize the data themselves and return an `AHTTP::Response`:

```crystal
class ArticleController < ATH::Controller
  def initialize(@serializer : ASR::SerializerInterface); end

  @[ARTA::Get("/article")]
  def article : AHTTP::Response
    context = ASR::SerializationContext.new
    context.add_exclusion_strategy MyExclusionStrategy.new

    AHTTP::Response.new @serializer.serialize(Article.new, :json, context), headers: HTTP::Headers{"content-type" => "application/json"}
  end
end
```

## Upgrade to 0.22.0

### Dedicated service for accessing annotations defined on a controller action and/or parameter

The `#annotation_configurations` getter on `ATH::Action` and `ATH::Controller::ParameterMetadata` has been removed.
Inject and use the new [ATH::AnnotationResolver](https://athenaframework.org/Framework/AnnotationResolver) service to access the annotations:

Before:

```crystal
# Action
request.action.annotation_configurations

# Parameter
parameter.annotation_configurations
```

After:

```crystal
# Action
@annotation_resolver.action_annotations(request)

# Parameter
@annotation_resolver.action_parameter_annotations(request, parameter.name)
```

### HTTP types extracted to dedicated component

The following types have been extracted from the `framework` component into the dedicated `http` component.
Any references will need their namespace updated from `Athena::Framework` (`ATH`) to `Athena::HTTP` (`AHTTP`):

- `Request`
- `Response`
- `ResponseHeaders`
- `RedirectResponse`
- `StreamedResponse`
- `BinaryFileResponse`
- `ParameterBag`
- `HeaderUtils`
- `IPUtils`
- `RequestStore`
- `AbstractFile`
- `UploadedFile`
- `RequestMatcher`
- `RequestMatcher::Attributes`
- `RequestMatcher::Header`
- `RequestMatcher::Hostname`
- `RequestMatcher::Method`
- `RequestMatcher::Path`
- `RequestMatcher::QueryParameter`
- `Exception::ConflictingHeaders`
- `Exception::SuspiciousOperation`
- `Exception::RequestExceptionInterface`
- `Exception::File`
- `Exception::FileNotFound`
- `Exception::FileSizeLimitExceeded`
- `Exception::Logic`

### Request/Response handling types extracted to dedicated component

The following types have been extracted from the `framework` component into the dedicated `http_kernel` component.
Any references will need their namespace updated from `Athena::Framework` (`ATH`) to `Athena::HTTPKernel` (`AHK`):

- `Action`
- `ActionBase`
- `Controller::ArgumentResolver`
- `Controller::ArgumentResolverInterface`
- `Controller::ParameterMetadata`
- `Controller::ValueResolvers::DefaultValue`
- `Controller::ValueResolvers::Request`
- `Controller::ValueResolvers::RequestAttribute`
- `ErrorRenderer`
- `ErrorRendererInterface`
- `Events::Action`
- `Events::Exception`
- `Events::Request`
- `Events::RequestAware`
- `Events::Response`
- `Events::SettableResponse`
- `Events::Terminate`
- `Events::View`
- `Exception::BadGateway`
- `Exception::BadRequest`
- `Exception::Conflict`
- `Exception::Forbidden`
- `Exception::Gone`
- `Exception::HTTPException`
- `Exception::LengthRequired`
- `Exception::Logic`
- `Exception::MethodNotAllowed`
- `Exception::NotAcceptable`
- `Exception::NotFound`
- `Exception::NotImplemented`
- `Exception::PreconditionFailed`
- `Exception::ServiceUnavailable`
- `Exception::TooManyRequests`
- `Exception::Unauthorized`
- `Exception::UnprocessableEntity`
- `Exception::UnsupportedMediaType`
- `Listeners::Error`
- `Listeners::Routing`

### Change how the `ATH::Action` is accessed

The `AHTTP::Request#action` getter used to access the matched `ATH::Action` instance has been removed.
The action is now stored within the request's attributes as `"_action"` and must be accessed via:
```crystal
request.attributes.get("_action", AHK::ActionBase)
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
