class IgnoreOnDeserialize
  include ASR::Serializable

  property name : String = "Fred"

  @[ASRA::IgnoreOnDeserialize]
  property password : String = "monkey"
end
