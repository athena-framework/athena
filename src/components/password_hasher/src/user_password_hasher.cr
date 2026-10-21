# Hashes and verifies the passwords of users, using the `APH::Interface` an `APH::FactoryInterface` returns for them.
#
# ```
# hasher = APH::UserPasswordHasher.new APH::Factory.new({User => APH::Native.new})
#
# user = User.new
# user.password = hasher.hash_password user, "password"
#
# hasher.password_valid? user, "password" # => true
# ```
class Athena::PasswordHasher::UserPasswordHasher
  include Athena::PasswordHasher::UserPasswordHasherInterface

  def initialize(@hasher_factory : APH::FactoryInterface); end

  # :inherit:
  def hash_password(user : APH::PasswordAuthenticatedUserInterface, plain_password : String) : String
    @hasher_factory.password_hasher(user).hash plain_password
  end

  # :inherit:
  def password_valid?(user : APH::PasswordAuthenticatedUserInterface, plain_password : String) : Bool
    return false unless password = user.password

    @hasher_factory.password_hasher(user).verify password, plain_password
  end

  # :inherit:
  def needs_rehash?(user : APH::PasswordAuthenticatedUserInterface) : Bool
    return false unless password = user.password

    @hasher_factory.password_hasher(user).needs_rehash? password
  end
end
