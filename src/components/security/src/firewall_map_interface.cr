# Returns the listeners of the firewall a request belongs to, see `ASEC::Firewall`.
module Athena::Security::FirewallMapInterface
  # Returns the listeners and the exception listener of the firewall the provided *request* belongs to.
  #
  # Returns no listeners and no exception listener if the *request* belongs to no firewall.
  abstract def listeners(request : AHTTP::Request) : Tuple(Array(ASEC::Firewall::ListenerInterface), ASEC::Firewall::ExceptionListener?)
end
