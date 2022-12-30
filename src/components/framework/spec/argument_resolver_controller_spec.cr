require "./spec_helper"

struct ArgumentResolverControllerTest < ATH::Spec::APITestCase
  def test_happy_path1 : Nil
    self.post("/argument-resolvers/float").body.should eq "3.14"
  end

  def test_happy_path2 : Nil
    self.post("/argument-resolvers/string").body.should eq %("fooo")
  end
end
