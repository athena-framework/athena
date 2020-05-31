require "./spec_helper"

describe ART::ParameterBag do
  describe "#has?" do
    it "returns false if that value isn't in the bag" do
      bag = ART::ParameterBag.new
      bag.has?("value").should be_false
    end

    it "returns true if that value is in the bag" do
      bag = ART::ParameterBag.new
      bag.set "value", "foo"
      bag.has?("value").should be_true
    end
  end

  describe "#get?" do
    it "returns nil if the value is missing" do
      bag = ART::ParameterBag.new
      bag.get?("value").should be_nil
    end

    it "returns the value is set" do
      bag = ART::ParameterBag.new
      bag.set "value", "foo"
      bag.get?("value").should eq "foo"
    end
  end

  describe "#get" do
    describe "by name" do
      it "raises if the value is missing" do
        bag = ART::ParameterBag.new
        expect_raises KeyError, "No parameter exists with the name 'value'." do
          bag.get "value"
        end
      end

      it "returns the value is set" do
        bag = ART::ParameterBag.new
        bag.set "value", "foo"
        bag.get("value").should eq "foo"
      end
    end

    describe "by name and type" do
      describe String do
        it do
          bag = ART::ParameterBag.new
          bag.set "value", "foo"
          value = bag.get "value", String
          value.should eq "foo"
          value.should be_a String
        end
      end

      describe Bool do
        it do
          bag = ART::ParameterBag.new
          bag.set "value", true
          value = bag.get "value", Bool
          value.should be_true
          value.should be_a Bool
        end
      end

      describe Int do
        it do
          bag = ART::ParameterBag.new
          bag.set "value", 123
          value = bag.get "value", Int32
          value.should eq 123
          value.should be_a Int32
        end
      end

      describe Float do
        it do
          bag = ART::ParameterBag.new
          bag.set "value", 3.14
          value = bag.get "value", Float64
          value.should eq 3.14
          value.should be_a Float64
        end
      end
    end
  end

  describe "#set" do
    describe "with name and type" do
      ART::ParameterBag.new.set("value", "foo", String)
    end
  end

  describe "#remove" do
    bag = ART::ParameterBag.new
    bag.set "value", "foo"
    bag.has?("value").should be_true
    bag.remove "value"
    bag.has?("value").should be_false
  end
end
