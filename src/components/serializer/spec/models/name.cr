class SerializedName
  include ASR::Serializable

  def initialize; end

  @[ASRA::Name(serialize: "myAddress")]
  property my_home_address : String = "123 Fake Street"

  @[ASRA::Name(deserialize: "some_key", serialize: "a_value")]
  property value : String = "str"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

class SerializedNameKey
  include ASR::Serializable

  def initialize; end

  @[ASRA::Name(key: "myAddress")]
  property my_home_address : String = "123 Fake Street"

  @[ASRA::Name(key: "some_key")]
  property value : String = "str"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(serialization_strategy: :camelcase)]
class SerializedNameCamelcaseSerializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(serialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(serialization_strategy: :underscore)]
class SerializedNameUnderscoreSerializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(serialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(serialization_strategy: :identical)]
class SerializedNameIdenticalSerializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(serialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(deserialization_strategy: :camelcase)]
class DeserializedNameCamelcaseDeserializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(deserialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(deserialization_strategy: :underscore)]
class DeserializedNameUnderscoreDeserializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(deserialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(deserialization_strategy: :identical)]
class DeserializedNameIdenticalDeserializationStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(deserialize: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(strategy: :camelcase)]
class SerializedNameCamelcaseStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(key: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(strategy: :underscore)]
class SerializedNameUnderscoreStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(key: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

@[ASRA::Name(strategy: :identical)]
class SerializedNameIdenticalStrategy
  include ASR::Serializable

  def initialize; end

  # Is overridable
  @[ASRA::Name(key: "myAdd_ress")]
  property my_home_address : String = "123 Fake Street"

  # ameba:disable Naming/VariableNames
  property two_wOrds : String = "two words"

  # ameba:disable Naming/VariableNames
  property myZipCode : Int32 = 90210
end

class DeserializedName
  include ASR::Serializable

  def initialize; end

  @[ASRA::Name(deserialize: "des")]
  property custom_name : Int32?

  property default_name : Bool?
end

class AliasName
  include ASR::Serializable

  def initialize; end

  @[ASRA::Name(aliases: ["val", "value", "some_value"])]
  property some_value : String?
end

class KeyName
  include ASR::Serializable

  def initialize; end

  @[ASRA::Name(key: "firstName")]
  property first_name : String?
end
