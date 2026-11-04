require "./spec_helper"

struct AccessMapTest < ASPEC::TestCase
  def test_returns_first_matched_attribute : Nil
    request = new_request
    request_matcher1 = MockRequestMatcher.new false
    request_matcher2 = MockRequestMatcher.new true
    request_matcher3 = MockRequestMatcher.new true

    map = ASEC::AccessMap.new
    map.add request_matcher1, "ROLE_ADMIN"
    map.add request_matcher2, "ROLE_USER"
    map.add request_matcher3, "ROLE_SUPER_ADMIN"

    map.attribute(request).should eq "ROLE_USER"
    request_matcher1.calls.should eq 1
    request_matcher2.calls.should eq 1
    request_matcher3.calls.should eq 0
  end

  def test_returns_nil_if_none_matched : Nil
    map = ASEC::AccessMap.new
    map.add MockRequestMatcher.new(false), "ROLE_USER"

    map.attribute(new_request).should be_nil
  end

  def test_rule_without_attribute : Nil
    request_matcher = MockRequestMatcher.new true

    map = ASEC::AccessMap.new
    map.add MockRequestMatcher.new(true)
    map.add request_matcher, "ROLE_USER"

    map.attribute(new_request).should be_nil
    request_matcher.calls.should eq 0
  end
end
