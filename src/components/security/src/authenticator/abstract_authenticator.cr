# The base type of authenticators that authenticate users with an `ASEC::Authenticator::Token::PostAuthentication`.
abstract class Athena::Security::Authenticator::AbstractAuthenticator
  include Athena::Security::Authenticator::Interface

  # :inherit:
  #
  # Creates an `ASEC::Authenticator::Token::PostAuthentication` with the roles of the user.
  def create_token(passport : ASEC::Authenticator::Passport, firewall_name : String) : ASEC::Authentication::Token::Interface
    user = passport.user

    ASEC::Authenticator::Token::PostAuthentication.new user, firewall_name, user.roles
  end
end
