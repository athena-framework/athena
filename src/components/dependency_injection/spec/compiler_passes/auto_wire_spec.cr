require "../spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
  CR
end

module AutoWireInterface; end

@[ADI::Register]
record AutoWireOne do
  include AutoWireInterface
end

@[ADI::Register]
record AutoWireTwo do
  include AutoWireInterface
end

@[ADI::Register(public: true)]
record AutoWireService, auto_wire_two : AutoWireInterface

module SameInstanceAliasInterface; end

@[ADI::Register]
@[ADI::AsAlias]
class SameInstancePrimary
  include SameInstanceAliasInterface
end

@[ADI::Register(public: true)]
record SameInstanceClient, a : SameInstancePrimary, b : SameInstanceAliasInterface

describe ADI::ServiceContainer do
  describe "compiler errors", tags: "compiled" do
    it "does not resolve an un-aliased interface when there is only 1 implementation" do
      assert_compile_time_error "Failed to resolve value for parameter 'a : SomeInterface' of service 'bar' (Bar).", <<-CR
        module SomeInterface; end

        @[ADI::Register]
        class Foo
          include SomeInterface
        end

        @[ADI::Register(public: true)]
        record Bar, a : SomeInterface

        ADI.container.bar
      CR
    end
  end

  it "resolves the service with a matching constructor name" do
    ADI.container.auto_wire_service.auto_wire_two.should be_a AutoWireTwo
  end

  it "resolves aliases to the same underlying instance" do
    service = ADI.container.same_instance_client
    service.a.should be service.b
  end
end
