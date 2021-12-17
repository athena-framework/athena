require "../spec_helper"

describe AVD::Violation::ConstraintViolationList do
  it "without any violations" do
    AVD::Violation::ConstraintViolationList.new.size.should eq 0
  end

  it "with violations" do
    violation = get_violation "error"

    list = AVD::Violation::ConstraintViolationList.new [violation]

    list.size.should eq 1
    list.first.should eq violation
  end

  it "#find_by_code" do
    list = AVD::Violation::ConstraintViolationList.new [get_violation("one", code: "CODE"), get_violation("two", code: "CODE"), get_violation("three", code: "CODE2")]

    new_list = list.find_by_code "CODE"

    new_list.should be_a AVD::Violation::ConstraintViolationList
    new_list.size.should eq 2
  end

  describe "#add" do
    it "adds the given violation" do
      violation = get_violation "error"

      list = AVD::Violation::ConstraintViolationList.new
      list.add violation

      list.size.should eq 1
      list.first.should eq violation
    end

    it "adds another list" do
      other_list = AVD::Violation::ConstraintViolationList.new [get_violation("one"), get_violation("two"), get_violation("three")]

      list = AVD::Violation::ConstraintViolationList.new
      list.add other_list

      list.size.should eq 3
      list[0].should eq other_list[0]
      list[1].should eq other_list[1]
      list[2].should eq other_list[2]
    end
  end

  it "#has?" do
    violation = get_violation "error"

    list = AVD::Violation::ConstraintViolationList.new

    list.has?(0).should be_false
    list.add violation
    list.has?(0).should be_true
    list.has?(1).should be_false
  end

  it "#set" do
    violation = get_violation "error"
    other_error = get_violation "other error"

    list = AVD::Violation::ConstraintViolationList.new [violation]

    list.first.should eq violation
    list.set 0, other_error
    list.first.should eq other_error
  end

  it "#remove" do
    violation = get_violation "error"

    list = AVD::Violation::ConstraintViolationList.new
    list.add violation

    list.size.should eq 1
    list.remove 0
    list.should be_empty
  end

  it "#to_s" do
    AVD::Violation::ConstraintViolationList.new([get_violation("Error 1", root: "Root", property_path: ""), get_violation("Error 2", root: "Root", property_path: "")]).to_s.should eq "Root:\n\tError 1\nRoot:\n\tError 2\n"
  end

  describe "#to_json" do
    it "serializes to an array of objects" do
      violations = AVD::Violation::ConstraintViolationList.new([get_violation("Error 1"), get_violation("Error 2", root: "Root")])
      violations.to_json.should eq %([{"property":"property_path","message":"Error 1"},{"property":"property_path","message":"Error 2"}])
    end
  end
end
