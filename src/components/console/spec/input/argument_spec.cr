require "../spec_helper"

describe ACON::Input::Argument do
  describe ".new" do
    it "disallows blank names" do
      expect_raises ACON::Exception::InvalidArgument, "An argument name cannot be blank." do
        ACON::Input::Argument.new ""
      end

      expect_raises ACON::Exception::InvalidArgument, "An argument name cannot be blank." do
        ACON::Input::Argument.new "   "
      end
    end
  end

  describe "#default=" do
    describe "when the argument is required" do
      it "raises if not nil" do
        argument = ACON::Input::Argument.new "foo", :required

        expect_raises ACON::Exception::Logic, "Cannot set a default value when the argument is required." do
          argument.default = "bar"
        end
      end

      it "allows nil" do
        ACON::Input::Argument.new("foo", :required).default = nil
      end
    end

    describe "array" do
      it "nil value" do
        argument = ACON::Input::Argument.new "foo", ACON::Input::Argument::Mode[:optional, :is_array]
        argument.default = nil
        argument.default.should eq [] of String
      end

      it "non array" do
        argument = ACON::Input::Argument.new "foo", ACON::Input::Argument::Mode[:optional, :is_array]

        expect_raises ACON::Exception::Logic, "Default value for an array argument must be an array." do
          argument.default = "bar"
        end
      end
    end
  end

  describe "#complete" do
    it "with an array" do
      values = ["foo", "bar"]
      suggestions = ACON::Completion::Suggestions.new

      argument = ACON::Input::Argument.new "foo", suggested_values: values

      argument.has_completion?.should be_true

      argument.complete ACON::Completion::Input.new, suggestions

      suggestions.suggested_values.map(&.value).should eq ["foo", "bar"]
    end

    it "with an block" do
      values = ["foo", "bar"]
      suggestions = ACON::Completion::Suggestions.new
      callback = Proc(ACON::Completion::Input, Array(String)).new { values }

      argument = ACON::Input::Argument.new "foo", suggested_values: callback

      argument.has_completion?.should be_true

      argument.complete ACON::Completion::Input.new, suggestions

      suggestions.suggested_values.map(&.value).should eq ["foo", "bar"]
    end
  end
end
