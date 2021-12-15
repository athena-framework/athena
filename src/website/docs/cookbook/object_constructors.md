## DB

The [Serializer][Athena::Serializer] component also has the concept of [Object Constructors][Athena::Serializer::ObjectConstructorInterface] that determine how a new object is constructed during deserialization. A use case could be retrieving the object from the database as part of a `PUT` request in order to apply the deserialized data onto it. This would allow it to retain the PK, any timestamps, or [ASRA::ReadOnly][ASRA::ReadOnly] values.

NOTE: This example uses the `Granite` ORM, but should work with others.

```crystal
# Define a custom `ASR::ObjectConstructorInterface` to allow
# sourcing the model from the database as part of `PUT`
# requests, and if the type is a `Granite::Base`.
#
# Alias our service to `ASR::ObjectConstructorInterface`
# so this implementation gets injected instead.
@[ADI::Register(alias: ASR::ObjectConstructorInterface)]
class DBObjectConstructor
  include Athena::Serializer::ObjectConstructorInterface

  # Inject `ATH::RequestStore` in order to have access to
  # the current request. Also inject `ASR::InstantiateObjectConstructor`
  # to act as our fallback constructor.
  def initialize(
    @request_store : ATH::RequestStore,
    @fallback_constructor : ASR::InstantiateObjectConstructor
  ); end

  # :inherit:
  def construct(navigator : ASR::Navigators::DeserializationNavigatorInterface, properties : Array(ASR::PropertyMetadataBase), data : ASR::Any, type)
    # Fallback on the default object constructor if
    # the type is not a `Granite` model.
    unless type <= Granite::Base
      return @fallback_constructor.construct navigator, properties, data, type
    end

    # Fallback on the default object constructor if
    # the current request is not a `PUT`.
    unless @request_store.request.method == "PUT"
      return @fallback_constructor.construct navigator, properties, data, type
    end

    # Lookup the object from the database;
    # assume the object has an `id` property.
    entity = type.find data["id"].as_i64

    # Return a `404` error if no record exists with the given ID.
    raise ATH::Exceptions::NotFound.new "An item with the provided ID could not be found." unless entity

    # Apply the updated properties to the retrieved record
    entity.apply navigator, properties, data

    # Return the entity
    entity
  end
end
```

This object constructor could then be used with `ATH::RequestBodyConverter` to support seamless model updates:

```crystal
@[ASRA::ExclusionPolicy(:all)]
class Article < Granite::Base
  include ASR::Serializable

  connection "default"
  table "articles"

  @[ASRA::Expose]
  column id : Int64, primary: true

  @[ASRA::Expose]
  column title : String
end

@[ATHA::Prefix("article")]
class ExampleController < ATH::Controller
  @[ATHA::Put(path: "")]
  @[ATHA::ParamConverter("article", converter: ATH::RequestBodyConverter)]
  def update_article(article : Article) : Article
    # Since we have an actual `Article` instance with the updates
    # from the JSON payload already applied,
    # we can simply save and return the article.
    article.save
    article
  end
end

ATH.run
```

For example, sending the request body to this endpoint:

```json
{
    "id": 1,
    "title": "NEW TITLE"
}
```

Would result in Athena providing an `Article` instance where `article.title # => NEW TITLE`. In this way, the record in the DB could be seamlessly updated by simply calling `#save` and returning the object. This is a much simpler approach that removes much of the boilerplate associated with updating a DB record since all of that is handled by the framework; including running any validations against the new values that were defined on the columns.
