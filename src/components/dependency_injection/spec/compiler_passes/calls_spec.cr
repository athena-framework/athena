require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

@[ADI::Register(public: true, calls: [
  {"foo"},
  {"foo", {3}},
  {"foo", {6}},
])]
class CallClient
  getter values = [] of Int32

  def foo(value : Int32 = 1)
    @values << value
  end
end

describe ADI::ServiceContainer do
  describe "compiler errors", tags: "compiled" do
    it "errors if the method of a call is empty" do
      assert_error "Method name cannot be empty.", <<-CR
        @[ADI::Register(calls: [{""}])]
        record Foo
      CR
    end

    it "errors if the method does not exist on the type" do
      assert_error "Failed to auto register service for 'foo' (Foo). Call references non-existent method 'foo'.", <<-CR
        @[ADI::Register(calls: [{"foo"}])]
        record Foo
      CR
    end
  end

  it "allows defining calls" do
    ADI.container.call_client.values.should eq [1, 3, 6]
  end
end
