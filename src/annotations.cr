# `Athena::Serializer` uses annotations to control how an object gets serialized and deserialized.
# This module includes all the default serialization and deserialization annotations. The `ASRA` alias can be used as a shorthand when applying the annotations.
module Athena::Serializer::Annotations
  # Allows using methods/modules to control how a property is retrieved/set.
  #
  # ## Fields
  # * `getter` - A method name whose return value will be used as the serialized value.
  # * `setter` - A method name that accepts the deserialized value.  Can be used to apply additional logic before setting the properties value.
  # * `converter` - A module that defines a `.deserialize` method.  Can be used to share common deserialization between types.
  # * `path : Tuple` - A set of keys used to navigate to a value during deserialization.  The value of the last key will be used as the property's value.
  #
  # ## Example
  #
  # ### Getter/Setter
  #
  # ```
  # class AccessorExample
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   @[ASRA::Accessor(getter: get_foo, setter: set_foo)]
  #   property foo : String = "foo"
  #
  #   private def set_foo(foo : String) : String
  #     @foo = foo.upcase
  #   end
  #
  #   private def get_foo : String
  #     @foo.upcase
  #   end
  # end
  #
  # ASR.serializer.serialize AccessorExample.new, :json                 # => {"foo":"FOO"}
  # ASR.serializer.deserialize AccessorExample, %({"foo":"bar"}), :json # => #<AccessorExample:0x7f5915e25c20 @foo="BAR">
  # ```
  #
  # ### Converter
  #
  # ```
  # module ReverseConverter
  #   def self.deserialize(navigator : ASR::Navigators::DeserializationNavigatorInterface, metadata : ASR::PropertyMetadataBase, data : ASR::Any) : String
  #     data.as_s.reverse
  #   end
  # end
  #
  # class ConverterExample
  #   include ASR::Serializable
  #
  #   @[ASRA::Accessor(converter: ReverseConverter)]
  #   getter str : String
  # end
  #
  # ASR.serializer.deserialize ConverterExample, %({"str":"jim"}), :json # => #<ConverterExample:0x7f9745fa6d60 @str="mij">
  # ```
  #
  # ### Path
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   getter id : Int64
  #
  #   @[ASRA::Accessor(path: {"stats", "HP"})]
  #   getter hp : Int32
  #
  #   @[ASRA::Accessor(path: {"stats", "Attack"})]
  #   getter attack : Int32
  #
  #   @[ASRA::Accessor(path: {"downs", -1, "last_down"})]
  #   getter last_down : Time
  # end
  #
  # DATA = <<-JSON
  # {
  #   "id": 1,
  #   "stats": {
  #     "HP": 45,
  #     "Attack": 49
  #   },
  #   "downs": [
  #     {
  #       "id": 1,
  #       "last_down": "2020-05-019T05:23:17Z"
  #     },
  #     {
  #       "id": 2,
  #       "last_down": "2020-04-07T12:34:56Z"
  #     }
  #   ]
  #
  # }
  # JSON
  #
  # ASR.serializer.deserialize Example, DATA, :json
  # # #<Example:0x7f43c4ddf580
  # #  @attack=49,
  # #  @hp=45,
  # #  @id=1,
  # #  @last_down=2020-04-07 12:34:56.0 UTC>
  # ```
  annotation Accessor; end

  # Can be applied to a type to control the order of properties when serialized.  Valid values: `:alphabetical`, and `:custom`.
  #
  # By default properties are ordered in the order in which they are defined.
  #
  # ## Fields
  # * `order` - Used to specify the order of the properties when using `:custom` ordering.
  #
  # ## Example
  #
  # ```
  # class Default
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property a : String = "A"
  #   property z : String = "Z"
  #   property two : String = "two"
  #   property one : String = "one"
  #   property a_a : Int32 = 123
  #
  #   @[ASRA::VirtualProperty]
  #   def get_val : String
  #     "VAL"
  #   end
  # end
  #
  # ASR.serializer.serialize Default.new, :json # => {"a":"A","z":"Z","two":"two","one":"one","a_a":123,"get_val":"VAL"}
  #
  # @[ASRA::AccessorOrder(:alphabetical)]
  # class Abc
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property a : String = "A"
  #   property z : String = "Z"
  #   property two : String = "two"
  #   property one : String = "one"
  #   property a_a : Int32 = 123
  #
  #   @[ASRA::VirtualProperty]
  #   def get_val : String
  #     "VAL"
  #   end
  # end
  #
  # ASR.serializer.serialize Abc.new, :json # => {"a":"A","a_a":123,"get_val":"VAL","one":"one","two":"two","z":"Z"}
  #
  # @[ASRA::AccessorOrder(:custom, order: ["two", "z", "get_val", "a", "one", "a_a"])]
  # class Custom
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property a : String = "A"
  #   property z : String = "Z"
  #   property two : String = "two"
  #   property one : String = "one"
  #   property a_a : Int32 = 123
  #
  #   @[ASRA::VirtualProperty]
  #   def get_val : String
  #     "VAL"
  #   end
  # end
  #
  # ASR.serializer.serialize Custom.new, :json # => {"two":"two","z":"Z","get_val":"VAL","a":"A","one":"one","a_a":123}
  # ```
  annotation AccessorOrder; end

  # Allows deserializing an object based on the value of a specific field.
  #
  # ## Fields
  # * `key : String` - The field that should be read from the data to determine the correct type.
  # * `map : Hash | NamedTuple` - Maps the possible `key` values to their corresponding types.
  #
  # ## Example
  #
  # ```
  # @[ASRA::Discriminator(key: "type", map: {point: Point, circle: Circle})]
  # abstract class Shape
  #   include ASR::Serializable
  #
  #   property type : String
  # end
  #
  # class Point < Shape
  #   property x : Int32
  #   property y : Int32
  # end
  #
  # class Circle < Shape
  #   property x : Int32
  #   property y : Int32
  #   property radius : Int32
  # end
  #
  # ASR.serializer.deserialize Shape, %({"type":"point","x":10,"y":20}), :json              # => #<Point:0x7fbbf7f8bc20 @type="point", @x=10, @y=20>
  # ASR.serializer.deserialize Shape, %({"type":"circle","x":30,"y":40,"radius":12}), :json # => #<Circle:0x7fbbf7f93c60 @radius=12, @type="circle", @x=30, @y=40>
  # ```
  annotation Discriminator; end

  # Indicates that a property should not be serialized/deserialized when used with `:none` `ASRA::ExclusionPolicy`.
  #
  # Also see, `ASRA::IgnoreOnDeserialize` and `ASRA::IgnoreOnSerialize`.
  #
  # ## Example
  #
  # ```
  # @[ASRA::ExclusionPolicy(:none)]
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property name : String = "Jim"
  #
  #   @[ASRA::Exclude]
  #   property password : String = "monkey"
  # end
  #
  # ASR.serializer.serialize Example.new, :json                                          # => {"name":"Jim"}
  # ASR.serializer.deserialize Example, %({"name":"Jim","password":"password1!"}), :json # => #<Example:0x7f6eec4b6a60 @name="Jim", @password="monkey">
  # ```
  #
  # !!!warning
  #     On deserialization, the excluded properties must be nilable, or have a default value.
  annotation Exclude; end

  # Defines the default exclusion policy to use on a class.  Valid values: `:none`, and `:all`.
  #
  # Used with `ASRA::Expose` and `ASRA::Exclude`.
  annotation ExclusionPolicy; end

  # Indicates that a property should be serialized/deserialized when used with `:all` `ASRA::ExclusionPolicy`.
  #
  # Also see, `ASRA::IgnoreOnDeserialize` and `ASRA::IgnoreOnSerialize`.
  #
  # ## Example
  #
  # ```
  # @[ASRA::ExclusionPolicy(:all)]
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   @[ASRA::Expose]
  #   property name : String = "Jim"
  #
  #   property password : String = "monkey"
  # end
  #
  # ASR.serializer.serialize Example.new, :json                                          # => {"name":"Jim"}
  # ASR.serializer.deserialize Example, %({"name":"Jim","password":"password1!"}), :json # => #<Example:0x7f6eec4b6a60 @name="Jim", @password="monkey">
  # ```
  #
  # !!!warning
  #     On deserialization, the excluded properties must be nilable, or have a default value.
  annotation Expose; end

  # Defines the group(s) a property belongs to.  Properties are automatically added to the `default` group
  # if no groups are explicitly defined.
  #
  # See `ASR::ExclusionStrategies::Groups`.
  annotation Groups; end

  # Indicates that a property should not be set on deserialization, but should be serialized.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   property name : String
  #
  #   @[ASRA::IgnoreOnDeserialize]
  #   property password : String?
  # end
  #
  # obj = ASR.serializer.deserialize Example, %({"name":"Jim","password":"monkey123"}), :json
  #
  # obj.password # => nil
  # obj.name     # => Jim
  #
  # obj.password = "foobar"
  #
  # ASR.serializer.serialize obj, :json # => {"name":"Jim","password":"foobar"}
  # ```
  annotation IgnoreOnDeserialize; end

  # Indicates that a property should be set on deserialization, but should not be serialized.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   property name : String
  #
  #   @[ASRA::IgnoreOnSerialize]
  #   property password : String?
  # end
  #
  # obj = ASR.serializer.deserialize Example, %({"name":"Jim","password":"monkey123"}), :json
  #
  # obj.password # => monkey123
  # obj.name     # => Jim
  #
  # obj.password = "foobar"
  #
  # ASR.serializer.serialize obj, :json # => {"name":"Jim"}
  # ```
  annotation IgnoreOnSerialize; end

  # Defines the `key` to use during (de)serialization.  If not provided, the name of the property is used.
  # Also allows defining aliases that can be used for that property when deserializing.
  #
  # ## Fields
  #
  # * `serialize : String` - The key to use for this property during serialization.
  # * `deserialize : String` - The key to use for this property during deserialization.
  # * `key` : String - The key to use for this property during (de)serialization.
  # * `aliases : Array(String)` - A set of keys to use for this property during deserialization; is equivalent to multiple `deserialize` keys.
  # * `serialization_strategy : Symbol` - Defines the default serialization naming strategy for this type.  Can be overridden using the `serialize` or `key` field.
  # * `deserialization_strategy : Symbol` - Defines the default deserialization naming strategy for this type.  Can be overridden using the `deserialize` or `key` field.
  # * `strategy : Symbol` - Defines the default (de)serialization naming strategy for this type.  Can be overridden using the `serialize`, `deserialize` or `key` fields.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   @[ASRA::Name(serialize: "myAddress")]
  #   property my_home_address : String = "123 Fake Street"
  #
  #   @[ASRA::Name(deserialize: "some_key", serialize: "a_value")]
  #   property both_names : String = "str"
  #
  #   @[ASRA::Name(key: "same")]
  #   property same_in_both_directions : String = "same for both"
  #
  #   @[ASRA::Name(aliases: ["val", "value", "some_value"])]
  #   property some_value : String = "some_val"
  # end
  #
  # ASR.serializer.serialize Example.new, :json # => {"myAddress":"123 Fake Street","a_value":"str","same":"same for both","some_value":"some_val"}
  #
  # obj = ASR.serializer.deserialize Example, %({"my_home_address":"555 Mason Ave","some_key":"deserialized from diff key","same":"same again","value":"some_other_val"}), :json
  #
  # obj.my_home_address         # => "555 Mason Ave"
  # obj.both_names              # => "deserialized from diff key"
  # obj.same_in_both_directions # => "same again"
  # obj.some_value              # => "some_other_val"
  # ```
  #
  # ### Naming Strategies
  #
  # By default the keys in the serialized data match exactly to the name of the property.
  # Naming strategies allow changing this behavior for all properties within the type.
  # The serialized name can still be overridden on a per-property basis via
  # using the `ASRA::Name` annotation with the `serialize`, `deserialize` or `key` field.
  # The strategy will be applied on serialization, deserialization or both, depending
  # on whether `serialization_strategy`, `deserialization_strategy` or `strategy` is used.
  #
  # The available naming strategies include:
  # * `:camelcase`
  # * `:underscore`
  # * `:identical`
  #
  # ```
  # @[ASRA::Name(strategy: :camelcase)]
  # class User
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property id : Int32 = 1
  #   property first_name : String = "Jon"
  #   property last_name : String = "Snow"
  # end
  #
  # ASR.serializer.serialize User.new, :json # => {"id":1,"firstName":"Jon","lastName":"Snow"}
  # ```
  annotation Name; end

  # Defines a callback method(s) that are ran directly after the object has been deserialized.
  #
  # ## Example
  #
  # ```
  # record Example, name : String, first_name : String?, last_name : String? do
  #   include ASR::Serializable
  #
  #   @[ASRA::PostDeserialize]
  #   private def split_name : Nil
  #     @first_name, @last_name = @name.split(' ')
  #   end
  # end
  #
  # obj = ASR.serializer.deserialize Example, %({"name":"Jon Snow"}), :json
  #
  # obj.name       # => Jon Snow
  # obj.first_name # => Jon
  # obj.last_name  # => Snow
  # ```
  annotation PostDeserialize; end

  # Defines a callback method that is executed directly after the object has been serialized.
  #
  # ## Example
  #
  # ```
  # @[ASRA::ExclusionPolicy(:all)]
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   @[ASRA::Expose]
  #   @name : String?
  #
  #   property first_name : String = "Jon"
  #   property last_name : String = "Snow"
  #
  #   @[ASRA::PreSerialize]
  #   private def pre_ser : Nil
  #     @name = "#{first_name} #{last_name}"
  #   end
  #
  #   @[ASRA::PostSerialize]
  #   private def post_ser : Nil
  #     @name = nil
  #   end
  # end
  #
  # ASR.serializer.serialize Example.new, :json # => {"name":"Jon Snow"}
  # ```
  annotation PostSerialize; end

  # Defines a callback method that is executed directly before the object has been serialized.
  #
  # ## Example
  #
  # ```
  # @[ASRA::ExclusionPolicy(:all)]
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   @[ASRA::Expose]
  #   @name : String?
  #
  #   property first_name : String = "Jon"
  #   property last_name : String = "Snow"
  #
  #   @[ASRA::PreSerialize]
  #   private def pre_ser : Nil
  #     @name = "#{first_name} #{last_name}"
  #   end
  #
  #   @[ASRA::PostSerialize]
  #   private def post_ser : Nil
  #     @name = nil
  #   end
  # end
  #
  # ASR.serializer.serialize Example.new, :json # => {"name":"Jon Snow"}
  # ```
  annotation PreSerialize; end

  # Indicates that a property is read-only and cannot be set during deserialization.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   property name : String
  #
  #   @[ASRA::ReadOnly]
  #   property password : String?
  # end
  #
  # obj = ASR.serializer.deserialize Example, %({"name":"Fred","password":"password1"}), :json
  #
  # obj.name     # => "Fred"
  # obj.password # => nil
  # ```
  #
  # !!!warning
  #     The property must be nilable, or have a default value.
  annotation ReadOnly; end

  # Represents the first version a property was available.
  #
  # See `ASR::ExclusionStrategies::Version`.
  #
  # !!!note
  #     Value must be a `SemanticVersion` version.
  annotation Since; end

  # Indicates that a property should not be serialized or deserialized.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property name : String = "Jim"
  #
  #   @[ASRA::Skip]
  #   property password : String = "monkey"
  # end
  #
  # ASR.serializer.deserialize Example, %({"name":"Fred","password":"foobar"}), :json # => #<Example:0x7fe4dc98bce0 @name="Fred", @password="monkey">
  # ASR.serializer.serialize Example.new, :json                                       # => {"name":"Fred"}
  # ```
  annotation Skip; end

  # Indicates that a property should not be serialized when it is empty.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property id : Int64 = 1
  #
  #   @[ASRA::SkipWhenEmpty]
  #   property value : String = "value"
  #
  #   @[ASRA::SkipWhenEmpty]
  #   property values : Array(String) = %w(one two three)
  # end
  #
  # obj = Example.new
  #
  # ASR.serializer.serialize obj, :json # => {"id":1,"value":"value","values":["one","two","three"]}
  #
  # obj.value = ""
  # obj.values = [] of String
  #
  # ASR.serializer.serialize obj, :json # => {"id":1}
  # ```
  #
  # !!!tip:
  #     Can be used on any type that defines an `#empty?` method.
  annotation SkipWhenEmpty; end

  # Represents the last version a property was available.
  #
  # See `ASR::ExclusionStrategies::Version`.
  #
  # !!!note
  #     Value must be a `SemanticVersion` version.
  annotation Until; end

  # Can be applied to a method to make it act like a property.
  #
  # ## Example
  #
  # ```
  # class Example
  #   include ASR::Serializable
  #
  #   def initialize; end
  #
  #   property foo : String = "foo"
  #
  #   @[ASRA::VirtualProperty]
  #   @[ASRA::Name(serialize: "testing")]
  #   def some_method : Bool
  #     false
  #   end
  #
  #   @[ASRA::VirtualProperty]
  #   def get_val : String
  #     "VAL"
  #   end
  # end
  #
  # ASR.serializer.serialize Example.new, :json # => {"foo":"foo","testing":false,"get_val":"VAL"}
  # ```
  #
  # !!!warning
  #     The return type restriction _MUST_ be defined.
  annotation VirtualProperty; end
end
