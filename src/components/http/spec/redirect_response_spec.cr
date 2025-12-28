require "./spec_helper"

describe AHTTP::RedirectResponse do
  describe ".new" do
    it "raises if the url is empty" do
      expect_raises(ArgumentError, "Cannot redirect to an empty URL.") do
        AHTTP::RedirectResponse.new ""
      end
    end

    it "allows passing a `Path` instance" do
      response = AHTTP::RedirectResponse.new Path["/app/assets/foo.txt"]

      response.status.should eq ::HTTP::Status::FOUND
      response.headers["location"].should eq "/app/assets/foo.txt"
      response.content.should be_empty
    end
  end

  describe "#status" do
    it "defaults to 302" do
      AHTTP::RedirectResponse.new("address").status.should eq ::HTTP::Status::FOUND
    end

    it "disallows non redirect codes" do
      expect_raises(ArgumentError, "'422' is not an HTTP redirect status code.") do
        AHTTP::RedirectResponse.new("address", 422)
      end
    end

    it Int do
      AHTTP::RedirectResponse.new("address", 301).status.should eq ::HTTP::Status::MOVED_PERMANENTLY
    end

    it ::HTTP::Status do
      AHTTP::RedirectResponse.new("address", ::HTTP::Status::MOVED_PERMANENTLY).status.should eq ::HTTP::Status::MOVED_PERMANENTLY
    end
  end

  describe "#headers" do
    it "with an empty url" do
      expect_raises(ArgumentError, "Cannot redirect to an empty URL.") do
        AHTTP::RedirectResponse.new("")
      end
    end

    it "adds the location header" do
      AHTTP::RedirectResponse.new("address").headers["location"].should eq "address"
    end
  end
end
