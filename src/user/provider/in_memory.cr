# Provides users that are kept in memory, e.g. defined in the configuration of the application.
#
# Useful for testing, prototyping, or applications with a few fixed users, such as a single admin.
# User identifiers are case insensitive.
#
# ```
# provider = ASEC::User::Provider::InMemory.new [
#   ASEC::User::InMemory.new("admin", "$2y$13$...", ["ROLE_ADMIN"]),
# ]
#
# provider.load_user_by_identifier("ADMIN").roles # => ["ROLE_ADMIN"]
# ```
class Athena::Security::User::Provider::InMemory
  include Athena::Security::User::Provider::Interface

  @users = Hash(String, ASEC::User::InMemory).new

  def initialize(users : Enumerable(ASEC::User::InMemory) = [] of ASEC::User::InMemory)
    users.each { |user| self.create_user user }
  end

  # Adds the provided *user* to this provider.
  #
  # Raises an `ASEC::Exception::Logic` if a user with the same identifier already exists.
  def create_user(user : ASEC::User::InMemory) : Nil
    user_identifier = user.user_identifier.downcase

    raise ASEC::Exception::Logic.new "Another user with the same username already exists." if @users.has_key? user_identifier

    @users[user_identifier] = user
  end

  # :inherit:
  def load_user_by_identifier(identifier : String) : ASEC::User::Interface
    self.copy self.user(identifier)
  end

  # :inherit:
  def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
    raise ASEC::Exception::UnsupportedUser.new "Instances of '#{user.class}' are not supported." unless user.is_a? ASEC::User::InMemory

    self.copy self.user(user.user_identifier)
  end

  # :inherit:
  def supports_class?(klass : ASEC::User::Interface.class) : Bool
    klass == ASEC::User::InMemory
  end

  private def copy(user : ASEC::User::InMemory) : ASEC::User::InMemory
    ASEC::User::InMemory.new user.user_identifier, user.password, user.roles.dup, user.enabled?
  end

  private def user(username : String) : ASEC::User::InMemory
    @users.fetch(username.downcase) do
      raise ASEC::Exception::UserNotFound.new "Username '#{username}' does not exist.", user_identifier: username
    end
  end
end
