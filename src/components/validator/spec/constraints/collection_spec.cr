require "../spec_helper"

describe AVD::Constraints::Collection do
  it "transforms non optional/required constraints to required" do
    constraint = AVD::Constraints::Collection.new({"name" => ic = AVD::Constraints::NotBlank.new})
    constraint.constraints.size.should eq 1
    c = constraint.constraints["name"]?.should be_a AVD::Constraints::Required
    c.constraints.should eq({0 => ic})
  end

  it "allows explicit required constraints" do
    constraint = AVD::Constraints::Collection.new({"name" => ic = AVD::Constraints::Required.new(nb = AVD::Constraints::NotBlank.new)})
    constraint.constraints.size.should eq 1
    c = constraint.constraints["name"]?.should be_a AVD::Constraints::Required
    c.should eq ic
    c.constraints.should eq({0 => nb})
  end

  it "allows explicit optional constraints" do
    constraint = AVD::Constraints::Collection.new({"name" => ic = AVD::Constraints::Optional.new(nb = AVD::Constraints::NotBlank.new)})
    constraint.constraints.size.should eq 1
    c = constraint.constraints["name"]?.should be_a AVD::Constraints::Optional
    c.should eq ic
    c.constraints.should eq({0 => nb})
  end
end
