# Upgrades the hashed password of the user once it is authenticated, if its password hasher needs to rehash it, e.g. because its cost was increased.
#
# See `ASEC::Listeners::PasswordMigrating`.
class Athena::Security::Authenticator::Passport::Badge::PasswordUpgrade
  include Athena::Security::Authenticator::Passport::Badge::Interface

  # Returns the upgrader persisting the new hashed password, if any.
  #
  # Without one, the password is upgraded through the user provider set on the `ASEC::Authenticator::Passport::Badge::User`, if it is an `ASEC::User::PasswordUpgraderInterface`.
  getter password_upgrader : ASEC::User::PasswordUpgraderInterface?

  @plaintext_password : String?

  # Creates a badge with the *plaintext_password* presented by the user, which is hashed into its new password, and optionally the *password_upgrader* persisting it.
  def initialize(plaintext_password : String, @password_upgrader : ASEC::User::PasswordUpgraderInterface? = nil)
    @plaintext_password = plaintext_password
  end

  # Erases the plaintext password presented by the user from this badge, and returns it.
  #
  # Raises an `ASEC::Exception::Logic` if it was already erased.
  def erase_plaintext_password : String
    password = @plaintext_password || raise ASEC::Exception::Logic.new "The password is erased as another listener already used this badge."

    @plaintext_password = nil

    password
  end

  # :inherit:
  def resolved? : Bool
    true
  end
end
