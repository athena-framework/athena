require "../spec_helper"

class TestObject
  include ASR::Serializable

  def initialize; end

  getter foo : Symbol = :foo
  getter bar : Float32 = 12.1_f32
  getter nest : NestedType = NestedType.new
end
