require "./spec_helper"

describe ATH::Controller do
  describe ".render" do
    it "creates a proper response for the template" do
      # ameba:disable Lint/UselessAssign
      name = "TEST"
      response = ATH::Controller.render "#{__DIR__}/assets/greeting.ecr"

      response.status.should eq HTTP::Status::OK
      response.headers["content-type"].should eq "text/html"
      response.content.chomp.should eq "Greetings, TEST!"
    end

    it "creates a proper response for the template with a layout" do
      # ameba:disable Lint/UselessAssign
      name = "TEST"
      response = ATH::Controller.render "#{__DIR__}/assets/greeting.ecr", "#{__DIR__}/assets/layout.ecr"

      response.status.should eq HTTP::Status::OK
      response.headers["content-type"].should eq "text/html"
      response.content.chomp.should eq "<h1>Content:</h1> Greetings, TEST!"
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

  it "#redirect_view" do
    response = TestController.new.redirect_view "URL", :im_a_teapot
    view = response.should be_a ATH::View(Nil)
    view.location.should eq "URL"
    view.status.should eq HTTP::Status::IM_A_TEAPOT
  end

  it "#route_redirect_view" do
    response = TestController.new.route_redirect_view "get_user_me"
    view = response.should be_a ATH::View(Nil)
    view.route.should eq "get_user_me"
    view.route_params.should be_empty
  end
end
