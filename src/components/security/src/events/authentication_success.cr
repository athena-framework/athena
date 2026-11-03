# Emitted once a user was authenticated, before its token is set on the token storage.
#
# Listeners may still reject the authentication by raising an `ASEC::Exception::Authentication`, e.g. `ASEC::Listeners::UserChecker`.
class Athena::Security::Events::AuthenticationSuccess < ACTR::EventDispatcher::Event
  # Returns the token of the authenticated user.
  getter authentication_token : ASEC::Authentication::Token::Interface

  def initialize(@authentication_token : ASEC::Authentication::Token::Interface); end
end
