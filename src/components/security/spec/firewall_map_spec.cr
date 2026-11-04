require "./spec_helper"

struct FirewallMapTest < ASPEC::TestCase
  def test_listeners : Nil
    map = ASEC::FirewallMap.new
    request = new_request
    calls = [] of String

    not_matching_matcher = MockRequestMatcher.new false
    map.add not_matching_matcher, [MockFirewallListener.new("not_matching", calls)]

    matching_matcher = MockRequestMatcher.new true
    the_listener = MockFirewallListener.new "the_listener", calls
    the_exception_listener = self.create_exception_listener
    map.add matching_matcher, [the_listener], the_exception_listener

    too_late_matcher = MockRequestMatcher.new true
    map.add too_late_matcher, [MockFirewallListener.new("too_late", calls)]

    listeners, exception_listener = map.listeners request

    listeners.should eq [the_listener]
    exception_listener.should be the_exception_listener
    not_matching_matcher.calls.should eq 1
    matching_matcher.calls.should eq 1
    too_late_matcher.calls.should eq 0
  end

  def test_listeners_with_an_entry_having_no_request_matcher : Nil
    map = ASEC::FirewallMap.new
    calls = [] of String

    not_matching_matcher = MockRequestMatcher.new false
    map.add not_matching_matcher, [MockFirewallListener.new("not_matching", calls)]

    the_listener = MockFirewallListener.new "the_listener", calls
    the_exception_listener = self.create_exception_listener
    map.add nil, [the_listener], the_exception_listener

    too_late_matcher = MockRequestMatcher.new true
    map.add too_late_matcher, [MockFirewallListener.new("too_late", calls)]

    listeners, exception_listener = map.listeners new_request

    listeners.should eq [the_listener]
    exception_listener.should be the_exception_listener
    too_late_matcher.calls.should eq 0
  end

  def test_listeners_with_no_matching_entry : Nil
    map = ASEC::FirewallMap.new
    not_matching_matcher = MockRequestMatcher.new false
    map.add not_matching_matcher, [MockFirewallListener.new("not_matching", [] of String)]

    listeners, exception_listener = map.listeners new_request

    listeners.should be_empty
    exception_listener.should be_nil
    not_matching_matcher.calls.should eq 1
  end

  def test_listeners_are_sorted_by_priority : Nil
    map = ASEC::FirewallMap.new
    calls = [] of String
    low = MockFirewallListener.new "low", calls, priority: -10
    first_default = MockFirewallListener.new "first_default", calls
    high = MockFirewallListener.new "high", calls, priority: 10
    second_default = MockFirewallListener.new "second_default", calls

    map.add listeners: [low, first_default, high, second_default]

    map.listeners(new_request)[0].should eq [high, first_default, second_default, low]
  end

  private def create_exception_listener : ASEC::Firewall::ExceptionListener
    ASEC::Firewall::ExceptionListener.new ASEC::Authentication::Token::Storage.new, ASEC::Authentication::TrustResolver.new, "main"
  end
end
