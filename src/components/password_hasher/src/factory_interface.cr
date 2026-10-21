# Returns the `APH::Interface` configured for a user.
module Athena::PasswordHasher::FactoryInterface
  # Returns the password hasher to use for the provided *user*.
  #
  # If the *user* is an `APH::PasswordHasherAwareInterface` that returns a hasher name, the hasher with that name is used.
  # Otherwise, it is the first one whose type the *user* is an instance of.
  #
  # Raises an `APH::Exception::Runtime` if no password hasher is configured for the *user*.
  abstract def password_hasher(user : APH::PasswordAuthenticatedUserInterface) : APH::Interface

  # :ditto:
  abstract def password_hasher(user : APH::PasswordHasherAwareInterface) : APH::Interface

  # Returns the password hasher with the provided *name*, which may also be the name of the type it is configured for.
  #
  # Raises an `APH::Exception::Runtime` if no password hasher is configured with that *name*.
  abstract def password_hasher(name : String) : APH::Interface
end
