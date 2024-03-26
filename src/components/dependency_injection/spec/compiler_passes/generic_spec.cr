require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

@[ADI::Register(Int32, Bool, public: true, name: "int_service")]
@[ADI::Register(Float64, Bool, public: true, name: "float_service")]
struct GenericServiceBase(T, B)
  def type
    {T, B}
  end
end

describe ADI::ServiceContainer::ResolveGenerics do
  describe "compiler errors", tags: "compiled" do
    it "errors if the generic service does not have a name." do
      assert_error "Failed to register services for 'Foo(T)'. Generic services must explicitly provide a name.", <<-CR
        @[ADI::Register]
        record Foo(T)
      CR
    end

    it "errors if the generic service does not provide the generic arguments." do
      assert_error "Failed to register service 'foo_service'. Generic services must provide the types to use via the 'generics' field.", <<-CR
        @[ADI::Register(name: "foo_service")]
        record Foo(T)
      CR
    end

    it "errors if there is a generic argument count mismatch." do
      assert_error "Failed to register service 'foo_service'. Expected 1 generics types got 2.", <<-CR
        @[ADI::Register(String, Bool, name: "foo_service")]
        record Foo(T)
      CR
    end
  end

  it "correctly initializes the service with the given generic arguments" do
    ADI.container.int_service.type.should eq({Int32, Bool})
    ADI.container.float_service.type.should eq({Float64, Bool})
  end
end
