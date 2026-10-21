# Hashes passwords with [bcrypt](https://en.wikipedia.org/wiki/Bcrypt), using the standard library's [Crypto::Bcrypt](https://crystal-lang.org/api/Crypto/Bcrypt.html) type.
#
# ```
# hasher = APH::Native.new
#
# hash = hasher.hash "password" # => "$2a$13$..."
#
# hasher.verify hash, "password"       # => true
# hasher.verify hash, "wrong_password" # => false
# ```
#
# Bcrypt only uses the first 72 bytes of a password, and ignores everything after a NUL byte.
# Passwords longer than 72 bytes, or that contain a NUL byte, are therefore hashed with SHA-512 first, so that all of their bytes are taken into account.
class Athena::PasswordHasher::Native
  include Athena::PasswordHasher::Interface

  # The range of supported *cost* values.
  COST_RANGE = Crypto::Bcrypt::COST_RANGE

  # Returns the cost factor used to hash passwords.
  # Each increment doubles the time it takes to hash a password.
  getter cost : Int32

  def initialize(@cost : Int32 = 13)
    raise APH::Exception::InvalidArgument.new "The cost must be in the range of #{COST_RANGE}." unless COST_RANGE.includes? @cost
  end

  # :inherit:
  def hash(plain_password : String) : String
    raise APH::Exception::InvalidPassword.new if self.password_too_long? plain_password

    Crypto::Bcrypt.new(self.bcrypt_key(plain_password), Random::Secure.random_bytes(Crypto::Bcrypt::SALT_SIZE), @cost).to_s
  end

  # :inherit:
  def verify(hashed_password : String, plain_password : String) : Bool
    return false if plain_password.empty? || self.password_too_long? plain_password
    return false unless password = self.parse hashed_password

    # TODO: Use `password.verify` with the pre-hashed password truncated to 72 bytes, and `Crypto::Bcrypt.hash_secret` in `#hash`, once the minimum supported Crystal version's `String` overloads of `Crypto::Bcrypt` accept 72 byte passwords.
    salt = Crypto::Bcrypt::Base64.decode password.salt, Crypto::Bcrypt::SALT_SIZE
    computed_password = Crypto::Bcrypt::Password.new Crypto::Bcrypt.new(self.bcrypt_key(plain_password), salt, password.cost).to_s

    Crypto::Subtle.constant_time_compare password.digest, computed_password.digest
  end

  # :inherit:
  def needs_rehash?(hashed_password : String) : Bool
    return true unless password = self.parse hashed_password

    password.cost != @cost
  end

  private def parse(hashed_password : String) : Crypto::Bcrypt::Password?
    # `Crypto::Bcrypt::Password.new` raises an `IndexError` when the salt is too short, an `ArgumentError` when the cost isn't a number, and accepts invalid salt characters that `#verify` would then raise on.
    # TODO: Drop this check once the minimum supported Crystal version's `Crypto::Bcrypt::Password.new` raises `Crypto::Bcrypt::Error` for every malformed hash.
    return unless hashed_password.matches? /\A\$2[aby]?\$\d{2}\$[.\/A-Za-z0-9]{53}\z/

    Crypto::Bcrypt::Password.new hashed_password
  rescue Crypto::Bcrypt::Error
    nil
  end

  # Returns the key bcrypt derives the hash from: the password followed by its NUL terminator, truncated to 72 bytes.
  private def bcrypt_key(plain_password : String) : Bytes
    if plain_password.bytesize > 72 || plain_password.includes? '\0'
      plain_password = Base64.strict_encode Digest::SHA512.digest plain_password
    end

    plain_password.to_unsafe.to_slice(Math.min(plain_password.bytesize + 1, 72)).clone
  end
end
