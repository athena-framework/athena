class Skip
  include ASR::Serializable

  def initialize; end

  property one : String = "one"

  @[ASRA::Skip]
  property two : String = "two"
end
