# Maps requests to the listeners of the firewall they belong to, via request matchers.
#
# A request belongs to the firewall of the first request matcher matching it.
#
# ```
# firewall_map = ASEC::FirewallMap.new
# firewall_map.add AHTTP::RequestMatcher::Path.new(%r(^/api)), api_listeners, api_exception_listener
# firewall_map.add nil, main_listeners, main_exception_listener
# ```
class Athena::Security::FirewallMap
  include Athena::Security::FirewallMapInterface

  @map = [] of Tuple(AHTTP::RequestMatcher::Interface?, Array(ASEC::Firewall::ListenerInterface), ASEC::Firewall::ExceptionListener?)

  # Adds a firewall for the requests matching the provided *request_matcher*, or every request if it is `nil`, made of the provided *listeners* and *exception_listener*.
  #
  # The *listeners* are called in order of their `ASEC::Firewall::ListenerInterface#priority`, then in the provided order.
  def add(
    request_matcher : AHTTP::RequestMatcher::Interface? = nil,
    listeners : Enumerable(ASEC::Firewall::ListenerInterface) = [] of ASEC::Firewall::ListenerInterface,
    exception_listener : ASEC::Firewall::ExceptionListener? = nil,
  ) : Nil
    sorted_listeners = listeners.map(&.as(ASEC::Firewall::ListenerInterface)).sort_by! { |listener| -listener.priority }

    @map << {request_matcher, sorted_listeners, exception_listener}
  end

  # :inherit:
  def listeners(request : AHTTP::Request) : Tuple(Array(ASEC::Firewall::ListenerInterface), ASEC::Firewall::ExceptionListener?)
    @map.each do |request_matcher, listeners, exception_listener|
      return {listeners, exception_listener} if request_matcher.nil? || request_matcher.matches?(request)
    end

    {[] of ASEC::Firewall::ListenerInterface, nil}
  end
end
