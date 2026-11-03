# Represents the user being authenticated, via its identifier and how to load it.
#
# The user is loaded by the user loader of this badge, or by the user provider of the firewall if it has none, see `ASEC::Listeners::UserProvider`.
#
# ```
# # Loaded by the user provider of the firewall.
# ASEC::Authenticator::Passport::Badge::User.new email
#
# # Loaded by the provided block.
# ASEC::Authenticator::Passport::Badge::User.new(api_token) do |token|
#   User.find_by_api_token token
# end
# ```
class Athena::Security::Authenticator::Passport::Badge::User
  include Athena::Security::Authenticator::Passport::Badge::Interface

  # The maximum length of a user identifier, in bytes.
  MAX_USERNAME_LENGTH = 4096

  # Returns the identifier of the user, e.g. its email address.
  getter user_identifier : String

  # Returns the proc loading the user from its identifier, returning `nil` if it does not exist, if any.
  getter user_loader : Proc(String, ASEC::User::Interface?)?

  # Returns the user provider loading the user, if it was set via `#user_provider=`.
  getter user_provider : ASEC::User::Provider::Interface? = nil

  @user : ASEC::User::Interface? = nil

  # Creates a badge for the user with the provided *user_identifier*, which is a unique string representing the user for this authentication.
  # The user is loaded by the block, which returns `nil` if the user does not exist.
  #
  # Raises an `ASEC::Exception::BadCredentials` if the *user_identifier* is empty, or longer than `MAX_USERNAME_LENGTH`.
  def self.new(user_identifier : String, &user_loader : String -> ASEC::User::Interface?) : self
    new user_identifier, user_loader
  end

  # Creates a badge for the user with the provided *user_identifier*, which is a unique string representing the user for this authentication.
  # The user is loaded by the provided *user_loader*, which returns `nil` if the user does not exist, if any.
  #
  # Raises an `ASEC::Exception::BadCredentials` if the *user_identifier* is empty, or longer than `MAX_USERNAME_LENGTH`.
  def initialize(@user_identifier : String, @user_loader : Proc(String, ASEC::User::Interface?)? = nil)
    raise ASEC::Exception::BadCredentials.new "Empty user identifier." if @user_identifier.empty?
    raise ASEC::Exception::BadCredentials.new "Username too long." if @user_identifier.bytesize > MAX_USERNAME_LENGTH
  end

  # Returns the user, loading it via the user loader the first time.
  #
  # Raises an `ASEC::Exception::UserNotFound` if the user does not exist, or an `ASEC::Exception::Logic` if this badge has no user loader.
  def user : ASEC::User::Interface
    if user = @user
      return user
    end

    unless user_loader = @user_loader
      raise ASEC::Exception::Logic.new "No user loader is configured, did you forget to register the 'ASEC::Listeners::UserProvider' listener?"
    end

    unless user = user_loader.call @user_identifier
      raise ASEC::Exception::UserNotFound.new user_identifier: @user_identifier
    end

    @user = user
  end

  # Sets the provided *user_loader*, loading the user from its identifier, returning `nil` if it does not exist.
  def user_loader=(@user_loader : Proc(String, ASEC::User::Interface?))
    @user_provider = nil
  end

  # Sets the provided *user_provider* as the user loader, loading the user via its `ASEC::User::Provider::Interface#load_user_by_identifier`.
  #
  # If the *user_provider* is also an `ASEC::User::PasswordUpgraderInterface`, `ASEC::Listeners::PasswordMigrating` upgrades the password of the user through it.
  def user_provider=(user_provider : ASEC::User::Provider::Interface)
    @user_loader = ->(identifier : String) { user_provider.load_user_by_identifier(identifier).as ASEC::User::Interface? }
    @user_provider = user_provider
  end

  # :inherit:
  def resolved? : Bool
    true
  end
end
