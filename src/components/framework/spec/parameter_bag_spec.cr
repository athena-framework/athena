require "./spec_helper"

private alias DATATYPE = Hash(String, Int32 | String)

describe ATH::ParameterBag do
  describe "#has?" do
    it "returns false if that value isn't in the bag" do
      bag = ATH::ParameterBag.new
      bag.has?("value").should be_false
    end

    it "returns true if that value is in the bag" do
      bag = ATH::ParameterBag.new
      bag.set "value", "foo"
      bag.has?("value").should be_true
    end

    describe "with type" do
      it "returns true with a valid type" do
        bag = ATH::ParameterBag.new
        bag.set "value", "foo"
        bag.set "num", 1
        bag.set "nil", nil
        bag.has?("value", String).should be_true
        bag.has?("num", Int32).should be_true
        bag.has?("nil", Nil).should be_true
      end

      it "returns false with a invalid type" do
        bag = ATH::ParameterBag.new
        bag.set "value", "foo"
        bag.set "num", 1
        bag.set "nil", nil
        bag.has?("value", Int32).should be_false
        bag.has?("nil", Int32).should be_false
        bag.has?("num", String).should be_false
        bag.has?("num", String?).should be_false
        bag.has?("num", Int32?).should be_false
        bag.has?("nil", Int32?).should be_false
      end
    end
  end

  describe "#get?" do
    it "returns nil if the value is missing" do
      bag = ATH::ParameterBag.new
      bag.get?("value").should be_nil
    end

    it "returns the value is set" do
      bag = ATH::ParameterBag.new
      bag.set "value", "foo"
      bag.get?("value").should eq "foo"
    end

    describe "with a complex T" do
      it "returns an nilable T" do
        bag = ATH::ParameterBag.new
        bag.set "data", {"foo" => "bar", "baz" => 10}, DATATYPE

        data = bag.get "data", DATATYPE
        data.class.should eq DATATYPE
        data["foo"].should eq "bar"
      end
    end

    it "returns nil if the value is set, but of a different type" do
      bag = ATH::ParameterBag.new
      bag.set "value", "foo"
      bag.get?("value", Int32).should be_nil
    end
  end

  describe "#get" do
    describe "by name" do
      it "raises if the value is missing" do
        bag = ATH::ParameterBag.new
        expect_raises KeyError, "No parameter exists with the name 'value'." do
          bag.get "value"
        end
      end

      it "returns the value is set" do
        bag = ATH::ParameterBag.new
        bag.set "value", "foo"
        bag.get("value").should eq "foo"
      end

      it "is able to get falsey values" do
        bag = ATH::ParameterBag.new
        bag.set "n", nil
        bag.set "f", false
        bag.get("n").should be_nil
        bag.get("f").should be_false
      end
    end

    describe "by name and type" do
      it String do
        bag = ATH::ParameterBag.new
        bag.set "value", "foo"
        value = bag.get "value", String
        value.should eq "foo"
        value.class.should eq String
      end

      it Bool do
        bag = ATH::ParameterBag.new
        bag.set "value", true
        value = bag.get "value", Bool
        value.should be_true
        value.class.should eq Bool
      end

      it Int do
        bag = ATH::ParameterBag.new
        bag.set "value", 123
        value = bag.get "value", Int32
        value.should eq 123
        value.class.should eq Int32
      end

      it Float do
        bag = ATH::ParameterBag.new
        bag.set "value", 3.14
        value = bag.get "value", Float64
        value.should eq 3.14
        value.class.should eq Float64
      end

      it Union do
        bag = ATH::ParameterBag.new
        bag.set "pi", 3.14, Float64
        bag.set "e", 2.71, Float64
        bag.set "fav", 16, Int32
        bag.set "data", {"foo" => "bar", "baz" => 10}, DATATYPE

        a, b, c = bag.get("pi", Float64), bag.get("e", Float64), bag.get("fav", Int32)
        (a + b + c).should eq 21.85

        data = bag.get "data", DATATYPE
        data.class.should eq DATATYPE
        data["foo"].should eq "bar"
      end
    end
  end

  describe "#set" do
    it "with name, type, and value" do
      ATH::ParameterBag.new.set("value", "foo", String)
    end

    it "with name and value" do
      ATH::ParameterBag.new.set("value", "foo")
    end
  end

  it "#remove" do
    bag = ATH::ParameterBag.new
    bag.set "value", "foo"
    bag.has?("value").should be_true
    bag.remove "value"
    bag.has?("value").should be_false
  end
end
