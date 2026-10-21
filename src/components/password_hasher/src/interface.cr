# Provides password hashing capabilities.
#
# Implementations are expected to generate their own salt, and store it as part of the hash.
module Athena::PasswordHasher::Interface
  # The maximum length, in bytes, of a plain password.
  # Longer passwords are rejected, as hashing them could be used as a denial of service vector.
  MAX_PASSWORD_LENGTH = 4096

  # Returns the hash of the provided *plain_password*.
  #
  # Raises an `APH::Exception::InvalidPassword` if the password is invalid, e.g. longer than `MAX_PASSWORD_LENGTH`.
  abstract def hash(plain_password : String) : String

  # Returns `true` if the provided *plain_password* matches the *hashed_password*, otherwise `false`.
  abstract def verify(hashed_password : String, plain_password : String) : Bool

  # Returns `true` if the provided *hashed_password* would benefit from being re-hashed, e.g. because it was hashed with a different algorithm or cost.
  abstract def needs_rehash?(hashed_password : String) : Bool

  private def password_too_long?(password : String) : Bool
    password.bytesize > MAX_PASSWORD_LENGTH
  end
end
