# Emitted while authenticating a user, to check the `ASEC::Authenticator::Passport` its authenticator created, e.g. by verifying its password.
#
# Listeners check the badges of the passport they handle, resolving them.
# They reject the authentication by raising an `ASEC::Exception::Authentication`.
class Athena::Security::Events::CheckPassport < ACTR::EventDispatcher::Event
  # Returns the authenticator that created the passport.
  getter authenticator : ASEC::Authenticator::Interface

  # Returns the passport to check.
  getter passport : ASEC::Authenticator::Passport

  def initialize(@authenticator : ASEC::Authenticator::Interface, @passport : ASEC::Authenticator::Passport); end
end
