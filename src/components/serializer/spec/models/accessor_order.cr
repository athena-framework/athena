class Default
  include ASR::Serializable

  def initialize; end

  property a : String = "A"
  property z : String = "Z"
  property two : String = "two"
  property one : String = "one"
  property a_a : Int32 = 123

  @[ASRA::VirtualProperty]
  def get_val : String
    "VAL"
  end
end

@[ASRA::AccessorOrder(:alphabetical)]
class Abc
  include ASR::Serializable

  def initialize; end

  property a : String = "A"
  property z : String = "Z"
  property one : String = "one"
  property a_a : Int32 = 123

  @[ASRA::Name(serialize: "two")]
  property zzz : String = "two"

  @[ASRA::VirtualProperty]
  def get_val : String
    "VAL"
  end
end

@[ASRA::AccessorOrder(:custom, order: ["two", "z", "get_val", "a", "one", "a_a"])]
class Custom
  include ASR::Serializable

  def initialize; end

  property a : String = "A"
  property z : String = "Z"
  property two : String = "two"
  property one : String = "one"
  property a_a : Int32 = 123

  @[ASRA::VirtualProperty]
  def get_val : String
    "VAL"
  end
end
