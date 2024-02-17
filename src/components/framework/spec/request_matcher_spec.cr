require "./spec_helper"

describe ATH::RequestMatcher do
  it "matches" do
    matcher = ATH::RequestMatcher.new(
      ATH::RequestMatcher::Path.new(%r(/admin/foo)),
      ATH::RequestMatcher::Method.new("GET"),
    )

    matcher.matches?(ATH::Request.new "GET", "/admin/foo").should be_true
  end

  it "does not match" do
    matcher = ATH::RequestMatcher.new(
      ATH::RequestMatcher::Method.new("POST"),
      ATH::RequestMatcher::Path.new(%r(/admin/foo)),
    )

    matcher.matches?(ATH::Request.new "GET", "/admin/foo").should be_false
  end
end
