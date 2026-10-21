# Hashes passwords with a *best_hasher*, while still verifying passwords hashed by any of the *extra_hashers*.
#
# This allows changing the hashing algorithm of existing users without invalidating their passwords.
# Passwords hashed by an extra hasher need a rehash, which an `APH::UserPasswordHasherInterface#needs_rehash?` check can catch when the user logs in.
#
# ```
# # Where `Argon2Hasher` is a custom `APH::Interface` implementation, e.g. using a third-party argon2 shard.
# hasher = APH::Migrating.new Argon2Hasher.new, APH::Native.new
#
# bcrypt_hash = APH::Native.new.hash "password"
#
# hasher.verify bcrypt_hash, "password" # => true
# hasher.needs_rehash? bcrypt_hash      # => true
# ```
#
# WARNING: Do not use a hasher that stores passwords in plain text as an extra hasher, otherwise a leaked hash could be used as the password itself.
class Athena::PasswordHasher::Migrating
  include Athena::PasswordHasher::Interface

  @extra_hashers : Array(APH::Interface)

  def initialize(@best_hasher : APH::Interface, *extra_hashers : APH::Interface)
    @extra_hashers = extra_hashers.map(&.as APH::Interface).to_a
  end

  # :inherit:
  #
  # Uses the best hasher.
  def hash(plain_password : String) : String
    @best_hasher.hash plain_password
  end

  # :inherit:
  #
  # The extra hashers are only tried if the *hashed_password* needs a rehash according to the best hasher.
  def verify(hashed_password : String, plain_password : String) : Bool
    return true if @best_hasher.verify hashed_password, plain_password
    return false unless @best_hasher.needs_rehash? hashed_password

    @extra_hashers.any? &.verify(hashed_password, plain_password)
  end

  # :inherit:
  #
  # Uses the best hasher.
  def needs_rehash?(hashed_password : String) : Bool
    @best_hasher.needs_rehash? hashed_password
  end
end
