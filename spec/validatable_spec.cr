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

describe AVD::Validatable do
  describe ".load_metadata" do
    it "should manually add constraints to the metadata object" do
      ManualConstraints.validation_class_metadata.constrained_properties.should eq ["name"]
    end
  end

  describe ".validation_class_metadata" do
    it "is inheritted when included in parent type" do
      Child.validation_class_metadata.constrained_properties.should eq ["name"]
    end

    it "is not defined for abstract types" do
      Parent.responds_to?(:validation_class_metadata).should be_false
    end

    it "is defined when included directly into non-abstract types" do
      Obj.validation_class_metadata.constrained_properties.should eq ["name"]
    end
  end
end
