require "../spec_helper"

struct MethodRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    {"get", "get", true},
    {"get", ["get", "post"], true},
    {"get", "post", false},
    {"get", "GET", true},
    {"get", ["GET", "POST"], true},
    {"get", "POST", false},
  )]
  def test_matches(request_method : String, matcher_methods : String | Enumerable(String), is_match : Bool) : Nil
    matcher = ATH::RequestMatcher::Method.new matcher_methods
    request = ATH::Request.new request_method, "/"
    matcher.matches?(request).should eq is_match
  end
end
