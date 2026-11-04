# Credentials made of the password presented by the user, which `ASEC::Listeners::CheckCredentials` verifies against the hashed password of the user.
#
# The user must include [APH::PasswordAuthenticatedUserInterface](/PasswordHasher/PasswordAuthenticatedUserInterface/).
class Athena::Security::Authenticator::Passport::Credentials::Password
  include Athena::Security::Authenticator::Passport::Credentials::Interface

  # :inherit:
  getter? resolved : Bool = false

  @password : String?

  def initialize(password : String)
    @password = password
  end

  # Returns the password presented by the user.
  #
  # Raises an `ASEC::Exception::Logic` if the password was already verified, which erases it.
  def password : String
    @password || raise ASEC::Exception::Logic.new "The credentials are erased as another listener already verified these credentials."
  end

  # :nodoc:
  def mark_resolved : Nil
    @resolved = true
    @password = nil
  end
end
