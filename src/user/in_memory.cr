# The user loaded by an `ASEC::User::Provider::InMemory`.
#
# It is not meant to be used for anything else.
class Athena::Security::User::InMemory
  include Athena::Security::User::Interface
  include Athena::Security::User::EquatableInterface
  include APH::PasswordAuthenticatedUserInterface

  # :inherit:
  getter user_identifier : String

  # :inherit:
  getter password : String?

  # :inherit:
  getter roles : Array(String)

  # Returns `true` if this user is enabled, otherwise `false`.
  #
  # Disabled users are prevented from logging in by an `ASEC::User::Checker::InMemory`.
  getter? enabled : Bool

  def initialize(username : String, @password : String?, @roles : Array(String) = [] of String, @enabled : Bool = true)
    raise ASEC::Exception::InvalidArgument.new "The username cannot be empty." if username.empty?

    @user_identifier = username
  end

  # :inherit:
  def equal_to?(user : ASEC::User::Interface) : Bool
    return false unless user.is_a? ASEC::User::InMemory

    return false if @password != user.password
    return false if @roles.size != user.roles.size || @roles.to_set != user.roles.to_set
    return false if @user_identifier != user.user_identifier
    return false if @enabled != user.enabled?

    true
  end

  def to_s(io : IO) : Nil
    io << @user_identifier
  end
end
