class IgnoreOnSerialize
  include ASR::Serializable

  def initialize; end

  property name : String = "Fred"

  @[ASRA::IgnoreOnSerialize]
  property password : String = "monkey"
end
