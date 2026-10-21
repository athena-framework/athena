require "spec"

require "athena-spec"
require "athena-console"
require "athena-console/spec"

require "../src/athena-password_hasher"

# Hidden questions would otherwise toggle the echo of the terminal running the specs.
# Class variables are per class, so it is disabled for the helper `ACON::Style::Athena` uses.
ACON::Helper::AthenaQuestion.disable_stty

class TestPasswordAuthenticatedUser
  include APH::PasswordAuthenticatedUserInterface

  property password : String?

  def initialize(@password : String? = nil); end
end

class SomeUser < TestPasswordAuthenticatedUser; end

class SomeChildUser < SomeUser; end

module IndirectPasswordAuthenticatedUserInterface
  include APH::PasswordAuthenticatedUserInterface
end

class IndirectUser
  include IndirectPasswordAuthenticatedUserInterface

  getter password : String? = nil
end

class HasherAwareOnlyUser
  include APH::PasswordHasherAwareInterface

  def password_hasher_name : String?
    nil
  end
end

class HasherAwareUser < TestPasswordAuthenticatedUser
  include APH::PasswordHasherAwareInterface

  property password_hasher_name : String? = "hasher_name"
end

# Returns *hash* from `#hash` and *valid* from `#verify`, while recording the calls made to it.
class MockPasswordHasher
  include APH::Interface

  getter calls = [] of {String, Array(String)}

  def initialize(@hash : String = "hash", @valid : Bool = true, @needs_rehash : Bool = false); end

  def hash(plain_password : String) : String
    @calls << {"hash", [plain_password]}
    @hash
  end

  def verify(hashed_password : String, plain_password : String) : Bool
    @calls << {"verify", [hashed_password, plain_password]}
    @valid
  end

  def needs_rehash?(hashed_password : String) : Bool
    @calls << {"needs_rehash?", [hashed_password]}
    @needs_rehash
  end
end

ASPEC.run_all
