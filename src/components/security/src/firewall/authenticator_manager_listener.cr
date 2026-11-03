# Authenticates the requests of a firewall via its `ASEC::Authentication::AuthenticatorManager`.
class Athena::Security::Firewall::AuthenticatorManagerListener
  include Athena::Security::Firewall::ListenerInterface

  def initialize(@authenticator_manager : ASEC::Authentication::AuthenticatorManager); end

  # :inherit:
  def supports?(request : AHTTP::Request) : Bool?
    @authenticator_manager.supports? request
  end

  # :inherit:
  def authenticate(event : AHK::Events::Request) : Nil
    return unless response = @authenticator_manager.authenticate_request event.request

    event.response = response
  end
end
