require "./spec_helper"

describe AVD::Constraint do
  describe ".error_name" do
    it "exists" do
      CustomConstraint.error_name("abc123").should eq "FAKE_ERROR"
    end

    it "does not add non _ERROR constants" do
      expect_raises(AVD::Exception::InvalidArgument, "The error code 'BLAH' does not exist for constraint of type 'CustomConstraint'.") do
        CustomConstraint.error_name "BLAH"
      end
    end

    it "does not exist" do
      expect_raises(AVD::Exception::InvalidArgument, "The error code 'foo' does not exist for constraint of type 'CustomConstraint'.") do
        CustomConstraint.error_name "foo"
      end
    end
  end

  describe "#add_implicit_group" do
    it "adds group when only group is default" do
      constraint = MockConstraint.new ""
      constraint.groups.should eq ["default"]
      constraint.add_implicit_group "foo"
      constraint.groups.should eq ["default", "foo"]
    end

    it "does not add when it's already included" do
      constraint = MockConstraint.new ""
      constraint.groups.should eq ["default"]
      constraint.add_implicit_group "foo"
      constraint.groups.should eq ["default", "foo"]
      constraint.add_implicit_group "foo"
      constraint.groups.should eq ["default", "foo"]
    end

    it "does not add when there are more than the default group" do
      constraint = MockConstraint.new "", groups: ["custom_group"]
      constraint.groups.should eq ["custom_group"]
      constraint.add_implicit_group "foo"
      constraint.groups.should eq ["custom_group"]
    end
  end

  describe "#initialize" do
    it "allows setting custom values" do
      constraint = CustomConstraint.new("MESSAGE", ["GROUP"], {"key" => "value"})
      constraint.message.should eq "MESSAGE"
      constraint.groups.should eq ["GROUP"]
      constraint.payload.should eq({"key" => "value"})
    end
  end
end
