# A listener of a firewall, which authenticates the requests it supports or checks their access, see `ASEC::Firewall`.
module Athena::Security::Firewall::ListenerInterface
  # Returns `true` if `#authenticate` should be called for the provided *request*, otherwise `false`.
  #
  # Returning `nil` also means that it should be called, but that it does not need to be before the token of the user is accessed.
  abstract def supports?(request : AHTTP::Request) : Bool?

  # Handles the request of the provided *event*, e.g. by authenticating its user.
  #
  # Set a response on the *event* to send it, which prevents later listeners of the firewall from being called.
  abstract def authenticate(event : AHK::Events::Request) : Nil

  # Returns the priority of this listener, listeners with a higher priority are called first.
  def priority : Int32
    0
  end
end
