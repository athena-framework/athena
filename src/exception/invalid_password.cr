# Raised when a plain password cannot be hashed, e.g. because it is longer than `APH::Interface::MAX_PASSWORD_LENGTH`.
class Athena::PasswordHasher::Exception::InvalidPassword < RuntimeError
  include Athena::PasswordHasher::Exception

  def initialize(message : String = "Invalid password.", cause : ::Exception? = nil)
    super message, cause
  end
end
