# Adds information to an `ASEC::Authenticator::Passport` that the security system checks while authenticating its user, e.g. a CSRF token.
module Athena::Security::Authenticator::Passport::Badge::Interface
  # Returns `true` if this badge was checked by the security system, otherwise `false`.
  #
  # Every badge of a passport must be resolved once it was checked, otherwise the authentication fails.
  abstract def resolved? : Bool
end
