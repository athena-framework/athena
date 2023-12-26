require "../spec_helper"

struct HostnameRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    { %r(.*.example.com), true },
    { %r(.example.com$), true },
    { %r(^.*.example.com$), true },
    { %r(.*.crystal.com), false },
    { %r(.*.example.COM), true },
    { %r(.example.COM$), true },
    { %r(^.*.example.COM$), true },
    { %r(.*.crystal.COM), false },
  )]
  def test_matches(regex : Regex, is_match : Bool) : Nil
    matcher = ATH::RequestMatcher::Hostname.new regex
    request = ATH::Request.new "GET", "/", HTTP::Headers{"host" => "foo.example.com"}
    matcher.matches?(request).should eq is_match
  end
end
