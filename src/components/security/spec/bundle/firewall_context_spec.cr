require "./spec_helper"

struct BundleFirewallContextTest < ASPEC::TestCase
  def test_listeners_are_sorted_by_priority : Nil
    calls = [] of String
    low = MockFirewallListener.new "low", calls, priority: -10
    first_default = MockFirewallListener.new "first_default", calls
    high = MockFirewallListener.new "high", calls, priority: 10
    second_default = MockFirewallListener.new "second_default", calls
    exception_listener = ASEC::Firewall::ExceptionListener.new ASEC::Authentication::Token::Storage.new, ASEC::Authentication::TrustResolver.new, "main"

    context = ASEC::Bundle::FirewallContext.new [low, first_default, high, second_default] of ASEC::Firewall::ListenerInterface, exception_listener

    context.listeners.should eq [high, first_default, second_default, low]
    context.exception_listener.should be exception_listener
  end
end
