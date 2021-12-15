class PreSerialize
  include ASR::Serializable

  def initialize; end

  getter name : String?
  getter age : Int32?

  @[ASRA::PreSerialize]
  def set_name : Nil
    @name = "NAME"
  end

  @[ASRA::PreSerialize]
  def set_age : Nil
    @age = 123
  end
end
