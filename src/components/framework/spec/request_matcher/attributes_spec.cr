require "../spec_helper"

struct AttributesRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    {"foo", %r(foo_.*), true},
    {"foo", %r(foo), true},
    {"foo", %r(^foo_bar$), true},
    {"foo", %r(barbar), false},
    {"some_num", %r(\d\d), false},
  )]
  def test_matches(key : String, regex : Regex, is_match : Bool) : Nil
    matcher = ATH::RequestMatcher::Attributes.new({key => regex})
    request = ATH::Request.new "GET", "/admin/foo"
    request.attributes.set "foo", "foo_bar"
    request.attributes.set "some_num", 42
    matcher.matches?(request).should eq is_match
  end
end
