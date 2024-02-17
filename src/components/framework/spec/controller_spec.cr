require "./spec_helper"

describe ATH::Controller do
  describe ".render" do
    it "creates a proper response for the template" do
      name = "TEST"
      response = ATH::Controller.render "#{__DIR__}/assets/greeting.ecr"

      response.status.should eq HTTP::Status::OK
      response.headers["content-type"].should eq "text/html"
      response.content.should eq "Greetings, TEST!#{EOL}"
    end

    it "creates a proper response for the template with a layout" do
      name = "TEST"
      response = ATH::Controller.render "#{__DIR__}/assets/greeting.ecr", "#{__DIR__}/assets/layout.ecr"

      response.status.should eq HTTP::Status::OK
      response.headers["content-type"].should eq "text/html"
      response.content.should eq "<h1>Content:</h1> Greetings, TEST!#{EOL}"
    end
  end

  describe "#redirect" do
    it "creates an ATH::RedirectResponse" do
      response = TestController.new.redirect "URL"

      response.status.should eq HTTP::Status::FOUND
      response.headers["location"].should eq "URL"
      response.content.should be_empty
    end

    it "allows passing a `Path` instance" do
      response = TestController.new.redirect Path["/app/assets/foo.txt"]

      response.status.should eq HTTP::Status::FOUND
      response.headers["location"].should eq "/app/assets/foo.txt"
      response.content.should be_empty
    end
  end
end
