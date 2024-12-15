require "../spec_helper"

struct HeaderRequestMatcherTest < ASPEC::TestCase
  @[TestWith(
    {HTTP::Headers{"x-foo" => "foo", "bar" => "bar", "baz" => "baz"}, true},
    {HTTP::Headers{"x-foo" => "foo", "bar" => "bar"}, true},
    {HTTP::Headers{"bar" => "bar", "baz" => "baz"}, false},
    {HTTP::Headers{"bar" => "bar"}, false},
    {HTTP::Headers.new, false},
  )]
  def test_matches(headers : HTTP::Headers, is_match : Bool) : Nil
    matcher = ATH::RequestMatcher::Header.new "x-foo", "bar"
    request = ATH::Request.new "GET", "/"

    headers.each do |k, v|
      request.headers[k] = v
    end

    matcher.matches?(request).should eq is_match
  end
end
