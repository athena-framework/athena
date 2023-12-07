require "../spec_helper"

private def assert_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_error message, <<-CR, line: line
    require "../spec_helper.cr"
    #{code}
    ADI::ServiceContainer.new
  CR
end

describe ADI::ServiceContainer::ValidateArguments do
  describe "compiler errors", tags: "compiler" do
    it "errors if a expects a string value parameter but it is not of that type" do
      assert_error "Parameter 'value : String' of service 'foo' (Foo) expects a String but got '123'.", <<-CR
        @[ADI::Register(_value: "%value%")]
        record Foo, value : String

        ADI.configure({
          parameters: {
            value: 123
          }
        })
      CR
    end

    it "errors if a parameter resolves to a service of the incorrect type" do
      assert_error "Parameter 'value : Int32' of service 'foo' (Foo) expects 'Int32' but the resolved service 'bar' is of type 'Bar'.", <<-CR
        @[ADI::Register]
        record Bar

        @[ADI::Register(_value: "@bar", public: true)]
        record Foo, value : Int32
      CR
    end
  end
end
