# Hashes and verifies the passwords of users, using the `APH::Interface` configured for them.
module Athena::PasswordHasher::UserPasswordHasherInterface
  # Returns the hash of the provided *plain_password* for the provided *user*.
  abstract def hash_password(user : APH::PasswordAuthenticatedUserInterface, plain_password : String) : String

  # Returns `true` if the provided *plain_password* matches the password of the provided *user*, otherwise `false`.
  #
  # Always returns `false` if the *user* has no password.
  abstract def password_valid?(user : APH::PasswordAuthenticatedUserInterface, plain_password : String) : Bool

  # Returns `true` if the password of the provided *user* would benefit from being re-hashed, otherwise `false`.
  #
  # Always returns `false` if the *user* has no password.
  abstract def needs_rehash?(user : APH::PasswordAuthenticatedUserInterface) : Bool
end
