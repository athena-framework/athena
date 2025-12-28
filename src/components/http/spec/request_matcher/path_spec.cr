require "../spec_helper"

struct PathRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    { %r(/admin/.*), true },
    { %r(/admin), true },
    { %r(^/admin/.*$), true },
    { %r(/blog/.*), false },
  )]
  def test_matches(regex : Regex, is_match : Bool) : Nil
    matcher = AHTTP::RequestMatcher::Path.new regex
    request = AHTTP::Request.new "GET", "/admin/foo"
    matcher.matches?(request).should eq is_match
  end

  def test_encoded_characters : Nil
    matcher = AHTTP::RequestMatcher::Path.new %r(^/admin/fo o*$)
    request = AHTTP::Request.new "GET", "/admin/fo%20o"
    matcher.matches?(request).should be_true
  end
end
