# Loads users from a source, such as a database or configuration, for the security component.
#
# When a user logs in, the provider loads the user with the identifier it entered, e.g. a username or email address.
# On subsequent requests, it refreshes the user so that changes to it, such as new roles, are taken into account.
#
# ```
# class UserProvider
#   include ASEC::User::Provider::Interface
#
#   def load_user_by_identifier(identifier : String) : ASEC::User::Interface
#     User.find_by_email(identifier) || raise ASEC::Exception::UserNotFound.new "User '#{identifier}' not found.", user_identifier: identifier
#   end
#
#   def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface
#     raise ASEC::Exception::UnsupportedUser.new "Instances of '#{user.class}' are not supported." unless user.is_a? User
#
#     self.load_user_by_identifier user.user_identifier
#   end
#
#   def supports_class?(klass : ASEC::User::Interface.class) : Bool
#     klass <= User
#   end
# end
# ```
module Athena::Security::User::Provider::Interface
  # Returns the user with the provided *identifier*, e.g. its username or email address.
  #
  # Raises an `ASEC::Exception::UserNotFound` if no user has that identifier.
  abstract def load_user_by_identifier(identifier : String) : ASEC::User::Interface

  # Returns an up to date instance of the provided *user*, e.g. reloaded from the database.
  #
  # Raises an `ASEC::Exception::UnsupportedUser` if the *user* is not supported, or an `ASEC::Exception::UserNotFound` if it no longer exists.
  abstract def refresh_user(user : ASEC::User::Interface) : ASEC::User::Interface

  # Returns `true` if this provider supports users of the provided *klass*, otherwise `false`.
  abstract def supports_class?(klass : ASEC::User::Interface.class) : Bool
end
