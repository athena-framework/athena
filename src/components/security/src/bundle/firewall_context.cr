# Holds the listeners and the exception listener of a firewall configured via the `ASEC::Bundle`.
class Athena::Security::Bundle::FirewallContext
  # Returns the listeners of the firewall, in order of their `ASEC::Firewall::ListenerInterface#priority`.
  getter listeners : Array(ASEC::Firewall::ListenerInterface)

  # Returns the exception listener of the firewall, or `nil` if security is disabled on it.
  getter exception_listener : ASEC::Firewall::ExceptionListener?

  def initialize(listeners : Array(ASEC::Firewall::ListenerInterface), @exception_listener : ASEC::Firewall::ExceptionListener?)
    @listeners = listeners.sort_by { |listener| -listener.priority }
  end
end
