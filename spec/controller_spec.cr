require "./spec_helper"

describe ART::Controller do
  describe "#render" do
    it "creates a proper response for the template" do
      # ameba:disable Lint/UselessAssign
      name = "TEST"
      response = ART::Controller.render "spec/greeting.ecr"

      response.status.should eq HTTP::Status::OK
      response.headers.should eq HTTP::Headers{"content-type" => "text/html"}
      response.io.rewind.gets_to_end.should eq "Greetings, TEST!\n"
    end
  end

  describe "#redirect" do
    it "creates an ART::RedirectResponse" do
      response = TestController.new.redirect "URL"

      response.status.should eq HTTP::Status::FOUND
      response.headers.should eq HTTP::Headers{"location" => "URL"}
      response.io.rewind.gets_to_end.should be_empty
    end
  end
end
