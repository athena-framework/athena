The `Athena::Serializer` component provides enhanced (de)serialization features,
with most leveraging [annotations](https://crystal-lang.org/reference/syntax_and_semantics/annotations/index.html).

## Installation

First, install the component by adding the following to your `shard.yml`, then running `shards install`:

```yaml
dependencies:
  athena-serializer:
    github: athena-framework/serializer
    version: ~> 0.4.0
```

## Usage

The `Athena::Serializer` component focuses around [ASR::Serializer][] implementations, with the default being [ASR::Serializer] as the main entrypoint into (de)serializing objects.
Usage wise, the component functions much like the `*::Serializable` modules in the stdlib, such as [JSON::Serializable](https://crystal-lang.org/api/JSON/Serializable.html).
The [ASR::Serializable][] module can be included into a type to make it (de)serializable.
From here various [annotations][ASR::Annotations] may be used to control how the object is (de)serialized.

```crystal
# ExclusionPolicy specifies that all properties should not be (de)serialized
# unless exposed via the `ASRA::Expose` annotation.
@[ASRA::ExclusionPolicy(:all)]
@[ASRA::AccessorOrder(:alphabetical)]
class Example
  include ASR::Serializable

  # Groups can be used to create different "views" of a type.
  @[ASRA::Expose]
  @[ASRA::Groups("details")]
  property name : String

  # The `ASRA::Name` controls the name that this property
  # should be deserialized from or be serialized to.
  # It can also be used to set the default serialized naming strategy on the type.
  @[ASRA::Expose]
  @[ASRA::Name(deserialize: "a_prop", serialize: "a_prop")]
  property some_prop : String

  # Define a custom accessor used to get the value for serialization.
  @[ASRA::Expose]
  @[ASRA::Groups("default", "details")]
  @[ASRA::Accessor(getter: get_title)]
  property title : String

  # ReadOnly properties cannot be set on deserialization
  @[ASRA::Expose]
  @[ASRA::ReadOnly]
  property created_at : Time = Time.utc

  # Allows the property to be set via deserialization,
  # but not exposed when serialized.
  @[ASRA::IgnoreOnSerialize]
  property password : String?

  # Because of the `:all` exclusion policy, and not having the `ASRA::Expose` annotation,
  # these properties are not exposed.
  getter first_name : String?
  getter last_name : String?

  # Runs directly after `self` is deserialized
  @[ASRA::PostDeserialize]
  def split_name : Nil
    @first_name, @last_name = @name.split(' ')
  end

  # Allows using the return value of a method as a key/value in the serialized output.
  @[ASRA::VirtualProperty]
  def get_val : String
    "VAL"
  end

  private def get_title : String
    @title.downcase
  end
end

obj = ASR.serializer.deserialize Example,
  %({"name":"FIRST LAST","a_prop":"STR","title":"TITLE","password":"monkey123","created_at":"2020-10-10T12:34:56Z"}), :json

obj
# => #<Example:0x7f3e3b106740 @created_at=2020-07-05 23:06:58.943298289 UTC, @name="FIRST LAST",
        @some_prop="STR", @title="TITLE", @password="monkey123", @first_name="FIRST", @last_name="LAST">

ASR.serializer.serialize obj, :json
# => {"a_prop":"STR","created_at":"2020-07-05T23:06:58.94Z","get_val":"VAL","name":"FIRST LAST","title":"title"}

ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.groups = ["details"]
# => {"name":"FIRST LAST","title":"title"}
```

## Learn More

* Customize how objects are [constructed][ASR::ObjectConstructorInterface]
* Make use of inheritance with [ASR::Model][]s
* Conditionally determine which (if any) properties should be [excluded][ASR::ExclusionStrategies::ExclusionStrategyInterface]
