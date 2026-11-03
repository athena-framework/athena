# Delegates to each of its providers in turn, until one of them is able to handle the request.
#
# ```
# provider = ASEC::User::Provider::Chain.new [
#   ASEC::User::Provider::InMemory.new([ASEC::User::InMemory.new("admin", "$2y$13$...", ["ROLE_ADMIN"])]),
#   DatabaseUserProvider.new,
# ] of ASEC::User::Provider::Interface
# ```
class Athena::Security::User::Provider::Chain
  include Athena::Security::User::Provider::Interface
  include Athena::Security::User::PasswordUpgraderInterface

  # Returns the providers this provider delegates to.
  getter providers : Array(ASEC::User::Provider::Interface)

  def initialize(@providers : Array(ASEC::User::Provider::Interface)); end

  # :inherit:
  def load_user_by_identifier(identifier : String) : ASEC::User::Interface
    @providers.each do |provider|
      return provider.load_user_by_identifier identifier
    rescue ASEC::Exception::UserNotFound
      # Try the next one
    end

    raise ASEC::Exception::UserNotFound.new "There is no user with identifier '#{identifier}'.", user_identifier: identifier
  end

  # :inherit:
  def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
    supported_user_found = false

    @providers.each do |provider|
      next unless provider.supports_class? user.class

      return provider.refresh_user user
    rescue ASEC::Exception::UnsupportedUser
      # Try the next one
    rescue ASEC::Exception::UserNotFound
      supported_user_found = true
      # Try the next one
    end

    if supported_user_found
      user_identifier = user.user_identifier

      raise ASEC::Exception::UserNotFound.new "There is no user with name '#{user_identifier}'.", user_identifier: user_identifier
    end

    raise ASEC::Exception::UnsupportedUser.new "There is no user provider for user '#{user.class}'. Shouldn't the 'supports_class?' method of your user provider return true for this class?"
  end

  # :inherit:
  def supports_class?(klass : ASEC::User::Interface.class) : Bool
    @providers.any? &.supports_class?(klass)
  end

  # :inherit:
  #
  # Upgrades the password via each provider that includes `ASEC::User::PasswordUpgraderInterface`.
  def upgrade_password(user : APH::PasswordAuthenticatedUserInterface, new_hashed_password : String) : Nil
    @providers.each do |provider|
      next unless provider.is_a? ASEC::User::PasswordUpgraderInterface

      begin
        provider.upgrade_password user, new_hashed_password
      rescue ASEC::Exception::UnsupportedUser
        # Ignore, password upgrades are opportunistic
      end
    end
  end
end
