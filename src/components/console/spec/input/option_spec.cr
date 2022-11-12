require "../spec_helper"

describe ACON::Input::Option do
  describe ".new" do
    it "normalizes the name" do
      ACON::Input::Option.new("--foo").name.should eq "foo"
    end

    it "disallows blank names" do
      expect_raises ACON::Exceptions::InvalidArgument, "An option name cannot be blank." do
        ACON::Input::Option.new ""
      end

      expect_raises ACON::Exceptions::InvalidArgument, "An option name cannot be blank." do
        ACON::Input::Option.new "   "
      end
    end

    describe "shortcut" do
      it "array" do
        ACON::Input::Option.new("foo", ["a", "b"]).shortcut.should eq "a|b"
      end

      it "string" do
        ACON::Input::Option.new("foo", "-a|b").shortcut.should eq "a|b"
      end

      it "string with whitespace" do
        ACON::Input::Option.new("foo", "a|  -b").shortcut.should eq "a|b"
      end

      it "string with different characters" do
        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut must consist of the same character, got 'ab'." do
          ACON::Input::Option.new "foo", "ab"
        end

        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut must consist of the same character, got 'aab'." do
          ACON::Input::Option.new "foo", "a|aa|aab"
        end
      end

      it "array with different characters" do
        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut must consist of the same character, got 'ab'." do
          ACON::Input::Option.new "foo", ["a", "ab"]
        end
      end

      it "blank" do
        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut cannot be blank." do
          ACON::Input::Option.new "foo", [] of String
        end

        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut cannot be blank." do
          ACON::Input::Option.new "foo", ""
        end

        expect_raises ACON::Exceptions::InvalidArgument, "An option shortcut cannot be blank." do
          ACON::Input::Option.new "foo", "   "
        end
      end
    end

    describe "value_mode" do
      it "NONE | IS_ARRAY" do
        expect_raises ACON::Exceptions::InvalidArgument, "Cannot have VALUE::IS_ARRAY option mode when the option does not accept a value." do
          ACON::Input::Option.new "foo", value_mode: ACON::Input::Option::Value::NONE | ACON::Input::Option::Value::IS_ARRAY
        end
      end

      it "NEGATABLE with value" do
        expect_raises ACON::Exceptions::InvalidArgument, "Cannot have VALUE::NEGATABLE option mode if the option also accepts a value." do
          ACON::Input::Option.new "foo", value_mode: ACON::Input::Option::Value::REQUIRED | ACON::Input::Option::Value::NEGATABLE
        end
      end
    end
  end

  describe "#default=" do
    it "does not allow a default if using Value::NONE" do
      expect_raises ACON::Exceptions::Logic, "Cannot set a default value when using Value::NONE mode." do
        ACON::Input::Option.new "foo", default: "bar"
      end
    end

    describe "array" do
      it "nil value" do
        option = ACON::Input::Option.new "foo", value_mode: ACON::Input::Option::Value::OPTIONAL | ACON::Input::Option::Value::IS_ARRAY
        option.default = nil
        option.default.should eq [] of String
      end

      it "non array" do
        option = ACON::Input::Option.new "foo", value_mode: ACON::Input::Option::Value::OPTIONAL | ACON::Input::Option::Value::IS_ARRAY

        expect_raises ACON::Exceptions::Logic, "Default value for an array option must be an array." do
          option.default = "bar"
        end
      end
    end
  end
end
