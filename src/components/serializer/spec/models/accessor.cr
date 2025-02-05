class GetterAccessor
  include ASR::Serializable

  def initialize; end

  @[ASRA::Accessor(getter: get_foo)]
  @foo : String = "foo"

  private def get_foo : String
    @foo.upcase
  end
end

class GetterAccessorDiffType
  include ASR::Serializable

  def initialize; end

  @[ASRA::Accessor(getter: get_value)]
  @value : Int32 = 10

  private def get_value : String
    (@value * 10).to_s
  end
end

class SetterAccessor
  include ASR::Serializable

  @[ASRA::Accessor(setter: set_foo)]
  getter foo : String

  private def set_foo(foo : String) : String
    foo.should eq "foo"
    @foo = "FOO"
  end
end
