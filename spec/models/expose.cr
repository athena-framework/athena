@[ASRA::ExclusionPolicy(:all)]
class Expose
  include ASR::Serializable

  def initialize; end

  @[ASRA::Expose]
  property name : String = "Jim"

  property password : String? = "monkey"
end
