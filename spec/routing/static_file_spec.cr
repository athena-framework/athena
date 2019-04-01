require "./routing_spec_helper"

do_with_config do |client|
  describe "Static files" do
    pending "should return correct file" do
      client.get("/test.txt").body.should eq File.read("spec/public/test.txt")
    end

    it "should 404 if file is missing" do
      response = client.get("/foo.txt")
      response.body.should eq %({"code":404,"message":"No route found for 'GET /foo.txt'"})
      response.status_code.should eq 404
    end
  end
end
