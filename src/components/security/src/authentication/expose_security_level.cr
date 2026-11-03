# Determines which authentication errors are shown to users, see `ASEC::Authentication::AuthenticatorManager`.
#
# Hidden errors are replaced with an `ASEC::Exception::BadCredentials`, as they reveal whether a user exists.
enum Athena::Security::Authentication::ExposeSecurityLevel
  # Hides `ASEC::Exception::UserNotFound` errors, and `ASEC::Exception::AccountStatus` errors other than `ASEC::Exception::CustomUserMessageAccountStatus` ones.
  None

  # Hides `ASEC::Exception::UserNotFound` errors.
  AccountStatus

  # Shows every error.
  All
end
