require "./spec_helper"

describe AHTTP::RequestMatcher do
  it "matches" do
    matcher = AHTTP::RequestMatcher.new(
      AHTTP::RequestMatcher::Path.new(%r(/admin/foo)),
      AHTTP::RequestMatcher::Method.new("GET"),
    )

    matcher.matches?(AHTTP::Request.new "GET", "/admin/foo").should be_true
  end

  it "does not match" do
    matcher = AHTTP::RequestMatcher.new(
      AHTTP::RequestMatcher::Method.new("POST"),
      AHTTP::RequestMatcher::Path.new(%r(/admin/foo)),
    )

    matcher.matches?(AHTTP::Request.new "GET", "/admin/foo").should be_false
  end
end
