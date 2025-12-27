require "../spec_helper"

struct QueryParameterRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    {"foo=&bar=", true},
    {"foo=foo1&bar=bar1", true},
    {"foo=foo1&bar=bar1&baz=baz1", true},
    {"foo=", false},
    {"", false},
  )]
  def test_matches(query_string : String, is_match : Bool) : Nil
    matcher = AHTTP::RequestMatcher::QueryParameter.new "foo", "bar"
    request = AHTTP::Request.new "GET", "/"
    request.query = query_string

    matcher.matches?(request).should eq is_match
  end
end
