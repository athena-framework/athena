require "./spec_helper"

private def new_exception_listener : ASEC::Firewall::ExceptionListener
  ASEC::Firewall::ExceptionListener.new ASEC::Authentication::Token::Storage.new, ASEC::Authentication::TrustResolver.new, "main"
end

struct BundleFirewallMapTest < ASPEC::TestCase
  def test_listeners_only_instantiates_the_matching_firewall : Nil
    calls = [] of String
    listener = MockFirewallListener.new "listener", calls
    exception_listener = new_exception_listener

    contexts = ADI::ServiceLocator(ASEC::Bundle::FirewallContext).new({
      "not_matching" => Proc(ASEC::Bundle::FirewallContext).new { raise "BUG: The firewall not matching the request was instantiated." },
      "matching"     => Proc(ASEC::Bundle::FirewallContext).new { ASEC::Bundle::FirewallContext.new [listener] of ASEC::Firewall::ListenerInterface, exception_listener },
      "too_late"     => Proc(ASEC::Bundle::FirewallContext).new { raise "BUG: The firewall after the matching one was instantiated." },
    })

    map = ASEC::Bundle::FirewallMap.new contexts, {
      "not_matching" => MockRequestMatcher.new(false),
      "matching"     => MockRequestMatcher.new(true),
      "too_late"     => nil,
    } of String => AHTTP::RequestMatcher::Interface?

    listeners, matched_exception_listener = map.listeners new_request

    listeners.should eq [listener]
    matched_exception_listener.should be exception_listener
  end

  def test_listeners_with_an_entry_having_no_request_matcher : Nil
    exception_listener = new_exception_listener

    contexts = ADI::ServiceLocator(ASEC::Bundle::FirewallContext).new({
      "main" => Proc(ASEC::Bundle::FirewallContext).new { ASEC::Bundle::FirewallContext.new [] of ASEC::Firewall::ListenerInterface, exception_listener },
    })

    map = ASEC::Bundle::FirewallMap.new contexts, {"main" => nil} of String => AHTTP::RequestMatcher::Interface?

    map.listeners(new_request)[1].should be exception_listener
  end

  def test_listeners_with_no_matching_entry : Nil
    contexts = ADI::ServiceLocator(ASEC::Bundle::FirewallContext).new({
      "main" => Proc(ASEC::Bundle::FirewallContext).new { raise "BUG: The firewall not matching the request was instantiated." },
    })

    map = ASEC::Bundle::FirewallMap.new contexts, {"main" => MockRequestMatcher.new(false)} of String => AHTTP::RequestMatcher::Interface?

    listeners, exception_listener = map.listeners new_request

    listeners.should be_empty
    exception_listener.should be_nil
  end
end
