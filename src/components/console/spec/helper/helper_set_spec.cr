require "../spec_helper"

describe ACON::Helper::HelperSet do
  describe "compiler errors", tags: "compiled" do
    it "when the provided helper type is not an `ACON::Helper::Interface`" do
      ASPEC::Methods.assert_compile_time_error "Helper class type 'String' is not an 'ACON::Helper::Interface'.", <<-CR
        require "../spec_helper.cr"

        ACON::Helper::HelperSet.new[String]?
      CR
    end
  end
end
