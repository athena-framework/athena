@[ASRA::ExclusionPolicy(:none)]
class Exclude
  include ASR::Serializable

  def initialize; end

  property name : String = "Jim"

  @[ASRA::Exclude]
  property password : String? = "monkey"
end
