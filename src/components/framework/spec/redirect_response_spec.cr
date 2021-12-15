require "./spec_helper"

describe ATH::RedirectResponse do
  describe ".new" do
    it "raises if the url is empty" do
      expect_raises(ArgumentError, "Cannot redirect to an empty URL.") do
        ATH::RedirectResponse.new ""
      end
    end

    it "allows passing a `Path` instance" do
      response = ATH::RedirectResponse.new Path["/app/assets/foo.txt"]

      response.status.should eq HTTP::Status::FOUND
      response.headers["location"].should eq "/app/assets/foo.txt"
      response.content.should be_empty
    end
  end

  describe "#status" do
    it "defaults to 302" do
      ATH::RedirectResponse.new("addresss").status.should eq HTTP::Status::FOUND
    end

    it "disallows non redirect codes" do
      expect_raises(ArgumentError, "'422' is not an HTTP redirect status code.") do
        ATH::RedirectResponse.new("addresss", 422)
      end
    end

    it Int do
      ATH::RedirectResponse.new("addresss", 301).status.should eq HTTP::Status::MOVED_PERMANENTLY
    end

    it HTTP::Status do
      ATH::RedirectResponse.new("addresss", HTTP::Status::MOVED_PERMANENTLY).status.should eq HTTP::Status::MOVED_PERMANENTLY
    end
  end

  describe "#headers" do
    it "with an empty url" do
      expect_raises(ArgumentError, "Cannot redirect to an empty URL.") do
        ATH::RedirectResponse.new("")
      end
    end

    it "adds the location header" do
      ATH::RedirectResponse.new("addresss").headers["location"].should eq "addresss"
    end
  end
end
