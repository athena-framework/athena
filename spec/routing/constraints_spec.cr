require "./routing_spec_helper"

describe "Constraints" do
  do_with_config

  describe "that is valid" do
    it "works" do
      CLIENT.get("/get/constraints/4:5:6").body.should eq "\"4:5:6\""
    end
  end

  describe "that is invalid" do
    it "returns correct error" do
      response = CLIENT.get("/get/constraints/4:a:6")
      response.body.should eq %({"code":404,"message":"No route found for 'GET /get/constraints/4:a:6'"})
      response.status.should eq HTTP::Status::NOT_FOUND
    end
  end
end
