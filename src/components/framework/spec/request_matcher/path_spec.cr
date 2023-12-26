require "../spec_helper"

struct PathRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    { %r(/admin/.*), true },
    { %r(/admin), true },
    { %r(^/admin/.*$), true },
    { %r(/blog/.*), false },
  )]
  def test_matches(regex : Regex, is_match : Bool) : Nil
    matcher = ATH::RequestMatcher::Path.new regex
    request = ATH::Request.new "GET", "/admin/foo"
    matcher.matches?(request).should eq is_match
  end

  def test_encoded_characters : Nil
    matcher = ATH::RequestMatcher::Path.new %r(^/admin/fo o*$)
    request = ATH::Request.new "GET", "/admin/fo%20o"
    matcher.matches?(request).should be_true
  end
end
