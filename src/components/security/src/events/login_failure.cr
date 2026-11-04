# Emitted when a user could not be authenticated, e.g. to throttle login attempts.
#
# Listeners may replace the response the authenticator returned.
class Athena::Security::Events::LoginFailure < ACTR::EventDispatcher::Event
  # Returns the exception that prevented authenticating the user.
  getter exception : ASEC::Exception::Authentication

  # Returns the authenticator that failed to authenticate the user.
  getter authenticator : ASEC::Authenticator::Interface

  # Returns the request the user tried to authenticate with.
  getter request : AHTTP::Request

  # The response to send, or `nil` to let the request continue.
  property response : AHTTP::Response?

  # Returns the name of the firewall the user tried to authenticate on.
  getter firewall_name : String

  # Returns the passport the authenticator created, or `nil` if it failed before creating one.
  getter passport : ASEC::Authenticator::Passport?

  def initialize(
    @exception : ASEC::Exception::Authentication,
    @authenticator : ASEC::Authenticator::Interface,
    @request : AHTTP::Request,
    @response : AHTTP::Response?,
    @firewall_name : String,
    @passport : ASEC::Authenticator::Passport? = nil,
  ); end
end
