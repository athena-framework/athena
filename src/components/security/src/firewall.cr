# Calls the listeners of the firewall each request belongs to, as determined by an `ASEC::FirewallMapInterface`, e.g. to authenticate its user and check its access.
#
# The listeners are called until one sets a response.
# The exception listener of the firewall then handles the security exceptions raised while handling the request, e.g. denying its access.
#
# ```
# firewall_map = ASEC::FirewallMap.new
# firewall_map.add(
#   AHTTP::RequestMatcher::Path.new(%r(^/api)),
#   [
#     ASEC::Firewall::AuthenticatorManagerListener.new(authenticator_manager),
#     ASEC::Firewall::AccessListener.new(token_storage, access_decision_manager, access_map),
#   ] of ASEC::Firewall::ListenerInterface,
#   ASEC::Firewall::ExceptionListener.new(token_storage, ASEC::Authentication::TrustResolver.new, "api"),
# )
#
# event_dispatcher.listener ASEC::Firewall.new firewall_map
# ```
class Athena::Security::Firewall
  def initialize(@map : ASEC::FirewallMapInterface); end

  @[AEDA::AsEventListener(priority: 8)]
  def on_request(event : AHK::Events::Request) : Nil
    request = event.request

    listeners, exception_listener = @map.listeners request

    # Stored on the request so that only the exceptions raised while handling it are handled by its firewall.
    request.attributes.set "_security_exception_listener", exception_listener unless exception_listener.nil?

    listeners.each do |listener|
      next if listener.supports?(request) == false

      listener.authenticate event

      break if event.response
    end
  end

  # Runs before `AHK::Listeners::Error`, so that security exceptions are handled before being rendered as errors.
  @[AEDA::AsEventListener(priority: 1)]
  def on_exception(event : AHK::Events::Exception) : Nil
    event.request.attributes.get?("_security_exception_listener", ASEC::Firewall::ExceptionListener).try &.on_exception event
  end
end
