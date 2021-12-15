[Exclusion Strategies][Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface] allow defining custom runtime logic that controls which properties should be (de)serialized.

## Request Method

In a web framework, being able to exclude a property based on the request method can be a handy tool. I.e. imagine having `IgnoreOnUpdate`, `IgnoreOnCreate`, and `IgnoreOnRead` annotations to specify how a specific property should behave as part of a `PUT`, `POST`, and `GET` request respectively. For example, allow a property to be set when an object is created, a `POST` request, but prevent it from being altered when it is updated, a `PUT` request.

```crystal
# Define and register our exclusion strategy
@[ADI::Register]
struct IgnoreOnMethodExclusionStrategy
  include Athena::Serializer::ExclusionStrategies::ExclusionStrategyInterface

  # Inject the `ATH::RequestStore` in order to have access
  # to the current request, and its method.
  def initialize(@request_store : ATH::RequestStore); end

  # :inherit:
  def skip_property?(metadata : ASR::PropertyMetadataBase, context : ASR::Context) : Bool
    # Don't skip if there isn't a request, such as a non web request context.
    return false unless requst_method = @request_store.request?.try &.method

    # Determine the annotation that should be read off the property.
    annotation_class = case requst_method
                       when "POST" then IgnoreOnCreate
                       when "PUT"  then IgnoreOnUpdate
                       when "GET"  then IgnoreOnRead
                       else             return false
                       end

    # Skip the property if it has the corresponding annotation.
    metadata.annotation_configurations.has? annotation_class
  end
end

# Define a custom serializer that is aliased to the `SerializerInterface`.
# This tells DI to inject this type when the interface is encountered.
#
# This step is mainly to globally enable our exclusion strategy.
# An alternate solution would be to have some global context factory
# method that would return a new `ATH::Context` object with or without
# the exclusion strategy applied to it that could be provided to the default serializer.
#
# This implementation was also chosen to demonstrate how default services can be extended by wrapping
# them in customer logic. In the future the Decorator pattern could also be added to the DI component.
@[ADI::Register(alias: Athena::Serializer::SerializerInterface)]
struct CustomSerializer
  include ASR::SerializerInterface

  # Inject the default serializer and our custom exclusion strategy.
  def initialize(
    @serializer : Athena::Serializer::Serializer,
    @ignore_on_method_exclusion_strategy : IgnoreOnMethodExclusionStrategy
  ); end

  # :inherit:
  #
  # For each method a part of the `SerializerInterface`, add our strategy to the context,
  # then call the default serializer with the modified context.
  def deserialize(type : _, input_data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
    context.add_exclusion_strategy @ignore_on_method_exclusion_strategy
    @serializer.deserialize type, input_data, format, context
  end

  # :inherit:
  def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String
    context.add_exclusion_strategy @ignore_on_method_exclusion_strategy
    @serializer.serialize data, format, context
  end

  # :inherit:
  def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
    context.add_exclusion_strategy @ignore_on_method_exclusion_strategy
    @serializer.serialize data, format, io, context
  end
end

# Register our `IgnoreOn*` annotations as configuration annotations.
ACF.configuration_annotation IgnoreOnCreate
ACF.configuration_annotation IgnoreOnUpdate
ACF.configuration_annotation IgnoreOnRead

# Define a type to test with.
record Article, id : Int32, author_id : Int32 = 100 do
  include ASR::Serializable

  @[IgnoreOnCreate]
  @author_id : Int32
end

# Register our controller as a service,
# be sure to define it as public.
@[ADI::Register(public: true)]
class ExampleController < ATH::Controller
  # Inject the serializer into the controller to test with.
  #
  # I'm using a controller because it's simpler, but this would
  # most likely be a part of an `ATH::ParamConverter`.
  def initialize(@serializer : ASR::SerializerInterface); end

  @[ATHA::Post("/article")]
  def new_article(request : ATH::Request) : Article
    @serializer.deserialize Article, request.body.not_nil!, :json
  end

  @[ATHA::Put("/article")]
  def update_article(request : ATH::Request) : Article
    @serializer.deserialize Article, request.body.not_nil!, :json
  end
end

# Run the server
ATH.run

# POST /article body: {"id":1,"author_id":2} # => {"id":1,"author_id":100}
# PUT /article body: {"id":1,"author_id":2} # => {"id":1,"author_id":2}
```

Since we marked `author_id` as `IgnoreOnCreate`, the default value is used during the `POST /article` request, while the user provided value is used for the `PUT /article` request.

A similar concept could also be applied to allow for ACL based exclusions. I.e. exclude properties if the current user doesn't have the required roles/permissions to view it.
