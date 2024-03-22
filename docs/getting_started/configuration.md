Some features need to be configured;
either to enable/control how they work, or to customize the default functionality.

<!-- ## `ATH.configure` -->

Configuration in Athena is mainly focused on controlling _how_ specific features/components provided by Athena itself, or third parties, function at runtime.
A more concrete example would be how [ATH::Config::CORS](/Framework/Config/CORS) can be used to control [ATH::Listeners::CORS](/Framework/Listeners/CORS).
Say we want to enable CORS for our application from our app URL, expose some custom headers, and allow credentials to be sent.
To do this we would want to redefine the configuration type's `self.configure` method.
This method should return an instance of `self`, configured how we wish. Alternatively, it could return `nil` to disable the listener, which is the default.

```crystal
def ATH::Config::CORS.configure
  new(
    allow_credentials: true,
    allow_origin: %(https://app.example.com),
    expose_headers: %w(X-Transaction-ID X-Some-Custom-Header),
  )
end
```

Configuration objects may also be injected as you would any other service. This can be especially helpful for Athena extensions created by third parties whom services should be configurable by the end use.

## Parameters

Parameters represent reusable configuration values that can be used when configuring the framework, or directly within the application's services.
For example, the URL of the application is a common piece of information, used both in configuration and other services for redirects.
This URl could be defined as a parameter to allow its definition to be centralized and reused.

Parameters should _NOT_ be used for values that rarely change, such as the max amount of items to return per page.
These types of values are better suited to being a [constant](https://crystal-lang.org/reference/syntax_and_semantics/constants.html) within the related type.
Similarly, infrastructure related values that change from one machine to another, e.g. development machine to production server, should be defined using environmental variables.

Parameters are intended for values that do not change between machines, and control the application's behavior, e.g. the sender of notification emails, what features are enabled, or other high level application level values.
To reiterate, the primary benefit of parameters is to centralize and decouple their values from the types that actually use them.
Another benefit is they offer full compile time safety, if for example, the type of `app_url` was mistakenly set to `Int32` or if the parameter's name was typo'd, e.g. `"%app.ap_url%"`; both would result in compile time errors.

<!-- ## Bundles -->

## Custom Annotations

Athena integrates the [Athena::Config](/Config) component's ability to define custom annotation configurations.
This feature allows developers to define custom annotations, and the data that should be read off of them, then apply/access the annotations on [ATH::Controller](/Framework/Controller) and/or [ATH::Action](/Framework/Action)s.

This is a powerful feature that allows for almost limitless flexibility/customization.
Some ideas include: storing some value in the request attributes and raise an exception or invoke some external service; all based on the presence/absence of it, a value read off of it, or either/both of those in-conjunction with an external service.
For example:

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

### Pagination

<!-- TODO: Move this to a cookbook/how-to type of page/section? -->

A good example use case for custom annotations is the creation of a `Paginated` annotation that can be applied to controller actions to have them be paginated via the listener. Generic pagination can be implemented via listening on the [view](./middleware.md#4-view-event) event which exposes the value returned via the related controller action.

```crystal

# Define our configuration annotation with the default pagination values.
# These values can be overridden on a per endpoint basis.
ACF.configuration_annotation Paginated, page : Int32 = 1, per_page : Int32 = 100, max_per_page : Int32 = 1000

# Define and register our listener that will handle paginating the response.
@[ADI::Register]
struct PaginationListener
  include AED::EventListenerInterface

  private PAGE_QUERY_PARAM     = "page"
  private PER_PAGE_QUERY_PARAM = "per_page"

  # Use a high priority to ensure future listeners are working with the paginated data
  @[AEDA::AsEventListener(priority: 255)]
  def on_view(event : ATH::Events::View) : Nil
    # Return if the endpoint is not paginated.
    return unless (pagination = event.request.action.annotation_configurations[Paginated]?)

    # Return if the action result is not able to be paginated.
    return unless (action_result = event.action_result).is_a? Indexable

    request = event.request

    # Determine pagination values; first checking the request's query parameters,
    # using the default values in the `Paginated` object if not provided.
    page = request.query_params[PAGE_QUERY_PARAM]?.try &.to_i || pagination.page
    per_page = request.query_params[PER_PAGE_QUERY_PARAM]?.try &.to_i || pagination.per_page

    # Raise an exception if `per_page` is higher than the max.
    raise ATH::Exceptions::BadRequest.new "Query param 'per_page' should be '#{pagination.max_per_page}' or less." if per_page > pagination.max_per_page

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
