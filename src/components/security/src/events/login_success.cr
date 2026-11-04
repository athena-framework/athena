# Emitted once a user was authenticated and its token was set on the token storage, e.g. to upgrade its password.
#
# Listeners may replace the response the authenticator returned.
class Athena::Security::Events::LoginSuccess < ACTR::EventDispatcher::Event
  # Returns the authenticator that authenticated the user.
  getter authenticator : ASEC::Authenticator::Interface

  # Returns the passport the user was authenticated with.
  getter passport : ASEC::Authenticator::Passport

  # Returns the token of the authenticated user.
  getter authenticated_token : ASEC::Authentication::Token::Interface

  # Returns the request the user was authenticated with.
  getter request : AHTTP::Request

  # The response to send, or `nil` to let the request continue.
  property response : AHTTP::Response?

  # Returns the name of the firewall the user was authenticated on.
  getter firewall_name : String

  # Returns the token that was set on the token storage before the user was authenticated, if any.
  getter previous_token : ASEC::Authentication::Token::Interface?

  def initialize(
    @authenticator : ASEC::Authenticator::Interface,
    @passport : ASEC::Authenticator::Passport,
    @authenticated_token : ASEC::Authentication::Token::Interface,
    @request : AHTTP::Request,
    @response : AHTTP::Response?,
    @firewall_name : String,
    @previous_token : ASEC::Authentication::Token::Interface? = nil,
  ); end

  # Returns the authenticated user.
  def user : ASEC::User::Interface
    @passport.user
  end
end
