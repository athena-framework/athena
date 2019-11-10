require "./routing_spec_helper"

describe "Static files" do
  do_with_config

  pending "should return correct file" do
    CLIENT.get("/test.txt").body.should eq File.read("spec/public/test.txt")
  end

  it "should 404 if file is missing" do
    response = CLIENT.get("/foo.txt")
    response.body.should eq %({"code":404,"message":"No route found for 'GET /foo.txt'"})
    response.status.should eq HTTP::Status::NOT_FOUND
  end
end
