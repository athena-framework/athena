# Resolves how much a token can be trusted, i.e. how its user authenticated.
module Athena::Security::Authentication::TrustResolverInterface
  # Returns `true` if the provided *token* represents an authenticated user, otherwise `false`.
  abstract def authenticated?(token : ASEC::Authentication::Token::Interface?) : Bool

  # Returns `true` if the provided *token* represents a fully authenticated user, i.e. one that proved its credentials during the current session, otherwise `false`.
  abstract def full_fledged?(token : ASEC::Authentication::Token::Interface?) : Bool
end
