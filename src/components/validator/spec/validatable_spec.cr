require "./spec_helper"

private class ManualConstraints
  include AVD::Validatable

  def self.load_metadata(class_metadata : AVD::Metadata::ClassMetadata) : Nil
    class_metadata.add_property_constraint "name", AVD::Constraints::EqualTo.new("foo")
  end

  def initialize(@name : String); end
end

private abstract class Parent
  include AVD::Validatable
end

private class Child < Parent
  @[Assert::NotBlank]
  property name : String = ""
end

private class Obj
  include AVD::Validatable

  @[Assert::NotBlank]
  property name : String = ""
end

private class InstanceCallbackClass
  include AVD::Validatable

  @[Assert::Callback]
  def validate(context : AVD::ExecutionContextInterface, payload : Hash(String, String)?) : Nil
  end
end

private class ClassCallbackClass
  include AVD::Validatable

  @[Assert::Callback]
  def self.validate(value : AVD::Constraints::Callback::ValueContainer, context : AVD::ExecutionContextInterface, payload : Hash(String, String)?) : Nil
  end
end

describe AVD::Validatable do
  describe ".load_metadata" do
    it "should manually add constraints to the metadata object" do
      ManualConstraints.validation_class_metadata.constrained_properties.should eq ["name"]
    end
  end

  describe ".validation_class_metadata" do
    it "is inherited when included in parent type" do
      Child.validation_class_metadata.constrained_properties.should eq ["name"]
    end

    it "is not defined for abstract types" do
      Parent.responds_to?(:validation_class_metadata).should be_false
    end

    it "is defined when included directly into non-abstract types" do
      Obj.validation_class_metadata.constrained_properties.should eq ["name"]
    end

    it "properly registers instance method callback constraints" do
      constraints = InstanceCallbackClass.validation_class_metadata.constraints
      constraints.size.should eq 1
      constraints.first.should be_a AVD::Constraints::Callback
    end

    it "properly registers class method callback constraints" do
      constraints = ClassCallbackClass.validation_class_metadata.constraints
      constraints.size.should eq 1
      constraints.first.should be_a AVD::Constraints::Callback
    end
  end
end
