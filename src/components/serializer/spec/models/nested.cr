require "../spec_helper"

class NestedType
  include ASR::Serializable

  def initialize; end

  getter active : Bool = true
end
