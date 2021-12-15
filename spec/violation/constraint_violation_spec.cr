require "../spec_helper"

record TestObj do
  include AVD::Validatable
end

describe AVD::Violation::ConstraintViolation do
  describe "#invalid_value" do
    it "returns the value" do
      get_violation("Message", invalid_value: 12.8).invalid_value.should eq 12.8
    end
  end

  describe "#to_s" do
    it Indexable do
      get_violation("Array", root: "Root", property_path: "property.path").to_s.should eq "Root.property.path:\n\tArray\n"
      get_violation("Array", root: "Root", property_path: "[2].value").to_s.should eq "Root[2].value:\n\tArray\n"
    end

    it Hash do
      get_violation("Some message", root: {"key" => "value"}, property_path: "key").to_s.should eq "Hash.key:\n\tSome message\n"
    end

    it "code" do
      get_violation("Some message", property_path: "key", code: "CODE").to_s.should eq "key:\n\tSome message (code: CODE)\n"
    end

    it AVD::Validatable do
      get_violation("Some message", root: TestObj.new, property_path: "").to_s.should eq "Object(TestObj):\n\tSome message\n"
    end
  end

  describe "#to_json" do
    it "without a code" do
      get_violation("Message", invalid_value: 12.8).to_json.should eq %({"property":"property_path","message":"Message"})
    end

    it "with a code" do
      get_violation("Message", invalid_value: 12.8, code: "CODE").to_json.should eq %({"property":"property_path","message":"Message","code":"CODE"})
    end

    it "with a root value" do
      get_violation("Message", invalid_value: 12.8, code: "CODE", root: "Root").to_json.should eq %({"property":"property_path","message":"Message","code":"CODE"})
    end
  end
end
