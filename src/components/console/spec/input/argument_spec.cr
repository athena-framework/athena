require "../spec_helper"

describe ACON::Input::Argument do
  describe ".new" do
    it "disallows blank names" do
      expect_raises ACON::Exceptions::InvalidArgument, "An argument name cannot be blank." do
        ACON::Input::Argument.new ""
      end

      expect_raises ACON::Exceptions::InvalidArgument, "An argument name cannot be blank." do
        ACON::Input::Argument.new "   "
      end
    end
  end

  describe "#default=" do
    describe "when the argument is required" do
      it "raises if not nil" do
        argument = ACON::Input::Argument.new "foo", :required

        expect_raises ACON::Exceptions::Logic, "Cannot set a default value when the argument is required." do
          argument.default = "bar"
        end
      end

      it "allows nil" do
        ACON::Input::Argument.new("foo", :required).default = nil
      end
    end

    describe "array" do
      it "nil value" do
        argument = ACON::Input::Argument.new "foo", ACON::Input::Argument::Mode.flags OPTIONAL, IS_ARRAY
        argument.default = nil
        argument.default.should eq [] of String
      end

      it "non array" do
        argument = ACON::Input::Argument.new "foo", ACON::Input::Argument::Mode.flags OPTIONAL, IS_ARRAY

        expect_raises ACON::Exceptions::Logic, "Default value for an array argument must be an array." do
          argument.default = "bar"
        end
      end
    end
  end
end
