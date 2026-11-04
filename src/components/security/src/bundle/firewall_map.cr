# Maps requests to the firewalls configured via the `ASEC::Bundle`, only instantiating the firewall a request belongs to.
#
# A request belongs to the firewall of the first request matcher matching it, while a `nil` request matcher matches every request.
class Athena::Security::Bundle::FirewallMap
  include Athena::Security::FirewallMapInterface

  # Creates a map of the firewalls whose context the provided *contexts* provide by their name.
  # The *map* holds the request matcher of each firewall, keyed by its name, in the order they are matched in.
  def initialize(
    @contexts : ADI::ServiceLocator(ASEC::Bundle::FirewallContext),
    @map : Hash(String, AHTTP::RequestMatcher::Interface?),
  ); end

  # :inherit:
  def listeners(request : AHTTP::Request) : Tuple(Array(ASEC::Firewall::ListenerInterface), ASEC::Firewall::ExceptionListener?)
    @map.each do |name, request_matcher|
      if request_matcher.nil? || request_matcher.matches?(request)
        context = @contexts.get name

        return {context.listeners, context.exception_listener}
      end
    end

    {[] of ASEC::Firewall::ListenerInterface, nil}
  end
end
