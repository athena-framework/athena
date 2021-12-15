class EmitNil
  include ASR::Serializable

  def initialize; end

  property name : String?
  property age : Int32 = 1
end
