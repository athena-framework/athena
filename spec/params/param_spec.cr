require "../spec_helper"

private struct MockParam(T) < ATH::Params::Param
  def default : Nil; end

  def type
    Nil
  end

  def extract_value(request : ATH::Request, default = nil) : Nil
  end
end

describe ATH::Params::Param do
  describe "#constraints" do
    it "nilable" do
      MockParam(Int32?).new("id", nilable: true).constraints.should be_empty
    end

    it "not nilable" do
      constraints = MockParam(Int32).new("id", nilable: false).constraints
      constraints.size.should eq 1
      constraints[0].should be_a AVD::Constraints::NotNil
    end
  end

  describe "#key" do
    it "with only a name" do
      MockParam(String).new("name").key.should eq "name"
    end

    it "with a name and key" do
      MockParam(String).new("name", key: "key").key.should eq "key"
    end
  end
end
