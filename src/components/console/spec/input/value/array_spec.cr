require "../../spec_helper"

describe ACON::Input::Value::Array do
  describe ".new" do
    it "without args" do
      array = ACON::Input::Value::Array.new
      array.value.should be_empty
      array.should be_empty
    end

    it "with args" do
      array = ACON::Input::Value::Array.from_array [1, "foo", false]
      array.value.size.should eq 3
      array << 10
      array.value.size.should eq 4
    end
  end

  it "#to_s" do
    ACON::Input::Value::Array
      .from_array([1, "foo", false])
      .to_s
      .should eq %(1,foo,false)
  end

  describe "#get" do
    it "non-nilable" do
      ACON::Input::Value::Array
        .from_array(arr = [1, 2, 3])
        .get(Array(Int32))
        .should eq arr
    end

    it "nilable" do
      ACON::Input::Value::Array
        .from_array(arr = ["foo", "bar"])
        .get(Array(String)?)
        .should eq arr
    end
  end
end
