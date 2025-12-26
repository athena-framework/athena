require "./spec_helper"

private def assert_compile_time_error(message : String, code : String, *, line : Int32 = __LINE__) : Nil
  ASPEC::Methods.assert_compile_time_error message, <<-CR, line: line
    require "./spec_helper.cr"
    #{code}
  CR
end

describe ADI::AbstractBundle do
  describe "compiler errors", tags: "compiled" do
    it "when the bundle does not inherit from ADI::AbstractBundle" do
      assert_compile_time_error "The provided bundle 'String' be inherit from 'ADI::AbstractBundle'.", <<-CR
        ADI.register_bundle String
      CR
    end

    it "when the bundle does not provide its name" do
      assert_compile_time_error "Unable to determine extension name. It was not provided as the first positional argument nor via the 'name' field.", <<-CR
        @[ADI::Bundle]
        struct MyBundle < ADI::AbstractBundle
        end

        ADI.register_bundle MyBundle
      CR
    end
  end
end
