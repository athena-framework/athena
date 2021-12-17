class VirtualProperty
  include ASR::Serializable

  def initialize; end

  property foo : String = "foo"

  @[ASRA::VirtualProperty]
  def get_val : String
    "VAL"
  end

  @[ASRA::VirtualProperty]
  @[ASRA::Groups("group1")]
  @[ASRA::Since("1.3.2")]
  @[ASRA::Until("1.2.3")]
  def group_version : String
    "group_version"
  end
end
