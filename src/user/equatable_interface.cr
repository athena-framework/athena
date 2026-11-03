# Allows a user to decide whether it is equal to another instance of itself, in the security context.
#
# Including it replaces the default comparison of the password, roles and identifier of a user when it is refreshed.
module Athena::Security::User::EquatableInterface
  # Returns `true` if this user and the provided *user* are equal in the security context, otherwise `false`.
  #
  # The comparison should not be based on the identity of the users, e.g. their IDs, but on the attributes that would require them to authenticate again when changed, such as their password.
  abstract def equal_to?(user : ASEC::User::Interface) : Bool
end
