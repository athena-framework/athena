# Emitted once the token of a newly authenticated user was created, before it is set on the token storage.
#
# Listeners may replace the token.
class Athena::Security::Events::AuthenticationTokenCreated < ACTR::EventDispatcher::Event
  # The token of the authenticated user.
  property authenticated_token : ASEC::Authentication::Token::Interface

  # Returns the passport the user was authenticated with.
  getter passport : ASEC::Authenticator::Passport

  def initialize(@authenticated_token : ASEC::Authentication::Token::Interface, @passport : ASEC::Authenticator::Passport); end
end
