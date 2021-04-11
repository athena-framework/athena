require "./spec_helper"

describe ART::Response::Headers, focus: true do
  describe "#initialize" do
    it "sets the date on creation" do
      headers = ART::Response::Headers.new
      headers.has_key?("date").should be_true
      headers.date.should_not(be_nil).should be_close Time.utc, 1.second
    end

    it "uses the provided date if supplied" do
      time = HTTP.format_time Time.utc 2021, 4, 7, 12, 0, 0
      headers = ART::Response::Headers.new({"date" => time})
      headers["date"].should eq time
    end

    it "reinitializes the date if removed" do
      time = HTTP.format_time Time.utc 2021, 4, 7, 12, 0, 0
      headers = ART::Response::Headers.new({"date" => time})
      headers.delete "date"

      headers.has_key?("date").should be_true
      headers["date"].should_not eq time
    end
  end

  describe "#[]=" do
    it "replaces previous values" do
      headers = ART::Response::Headers.new
      headers["cache-control"].should eq "no-cache, private"
      headers.has_cache_control_directive?("no-cache").should be_true

      headers["cache-control"] = "public"
      headers["cache-control"].should eq "public"
      headers.has_cache_control_directive?("public").should be_true

      headers["Cache-Control"] = "private"
      headers["cache-control"].should eq "private"
      headers.has_cache_control_directive?("private").should be_true
    end
  end

  describe "#date" do
    it "with a missing key" do
      headers = ART::Response::Headers.new
      headers.date("foo").should be_nil
    end

    it "with a missing key and custom default" do
      headers = ART::Response::Headers.new
      time = Time.utc 2021, 4, 7, 12, 0, 0
      headers.date("foo", time).should eq time
    end

    it "with an invalid datetime string" do
      ART::Response::Headers.new({"date" => "foo"}).date.should be_nil
    end
  end

  it "#get_cache_control_directive" do
    headers = ART::Response::Headers.new
    headers.add_cache_control_directive "private"
    headers.get_cache_control_directive("private").should be_true
    headers.get_cache_control_directive("public").should be_nil
  end

  describe "cache-control" do
    it "uses defaultes to conservative values" do
      headers = ART::Response::Headers.new
      headers["cache-control"].should eq "no-cache, private"
      headers.has_cache_control_directive?("no-cache").should be_true
    end

    it "uses what's provided if provided" do
      headers = ART::Response::Headers{"cache-control" => "public"}
      headers["cache-control"].should eq "public"
      headers.has_cache_control_directive?("public").should be_true
    end

    it "does not add anything if an etag is included" do
      headers = ART::Response::Headers{"etag" => "abc123"}
      headers["cache-control"].should eq "no-cache, private"
      headers.has_cache_control_directive?("private").should be_true
      headers.has_cache_control_directive?("no-cache").should be_true
      headers.has_cache_control_directive?("max-age").should be_false
    end

    it "includes special directive with last-modified header" do
      ART::Response::Headers.new({"expires" => "Sat, 10 Apr 2021 15:14:59 GMT"})["cache-control"].should eq "private, must-revalidate"
      ART::Response::Headers.new({"last-modified" => "Sat, 10 Apr 2021 15:14:59 GMT"})["cache-control"].should eq "private, must-revalidate"
      ART::Response::Headers.new({"last-modified" => "Sat, 10 Apr 2021 15:14:59 GMT", "etag" => "abc123"})["cache-control"].should eq "private, must-revalidate"
      ART::Response::Headers.new({"last-modified" => "Sat, 10 Apr 2021 15:14:59 GMT", "expires" => "Sat, 10 Apr 2021 15:14:59 GMT"})["cache-control"].should eq "private, must-revalidate"
    end

    it "adds 'private' to existing cache-control header that doesn't have private or public" do
      ART::Response::Headers{"expires" => "Sat, 10 Apr 2021 15:14:59 GMT", "cache-control" => "max-age=3600"}["cache-control"].should eq "max-age=3600, private"
    end

    it "does not add private or public with s-maxage" do
      ART::Response::Headers.new({"cache-control" => "s-maxage=100"})["cache-control"].should eq "s-maxage=100"
    end

    it "does not alter with multiple directives" do
      ART::Response::Headers.new({"cache-control" => "private, max-age=100"})["cache-control"].should eq "private, max-age=100"
      ART::Response::Headers.new({"cache-control" => "public, max-age=100"})["cache-control"].should eq "public, max-age=100"
    end

    it "recacluates cache-control when new header is added after creation" do
      headers = ART::Response::Headers.new
      headers["last-modified"] = "Sat, 10 Apr 2021 15:14:59 GMT"
      headers["cache-control"].should eq "private, must-revalidate"
    end

    it "recacluates cache-control when multiple directives are added" do
      headers = ART::Response::Headers.new
      headers["cache-control"] = "public"
      headers.add "cache-control", "immutable"
      headers["cache-control"].should eq "public, immutable"
    end
  end
end
