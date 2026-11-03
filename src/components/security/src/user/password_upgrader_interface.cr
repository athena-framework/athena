# Upgrades the hashed password of a user, e.g. after the cost of the hashing algorithm was increased.
#
# Typically included in the `ASEC::User::Provider::Interface` of the users, since it knows where they are stored.
module Athena::Security::User::PasswordUpgraderInterface
  # Persists the provided *new_hashed_password* of the provided *user*, and updates the *user* accordingly.
  #
  # Upgrades should be opportunistic, as users must still be able to log in when they fail.
  # It is fine for this method to do nothing, or to fail without raising.
  #
  # Raises an `ASEC::Exception::UnsupportedUser` if the *user* is not supported.
  abstract def upgrade_password(user : APH::PasswordAuthenticatedUserInterface, new_hashed_password : String) : Nil
end
