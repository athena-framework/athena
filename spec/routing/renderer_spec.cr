require "./routing_spec_helper"

describe Athena::Routing::Renderers do
  describe "yaml" do
    it "should render correctly" do
      CLIENT.get("/users/yaml/17").body.should eq "---\nid: 17\nage: 123\n"
    end
  end

  describe "ecr" do
    it "should render correctly" do
      CLIENT.get("/users/ecr/17").body.should eq "User 17 is 123 years old."
    end
  end
end
