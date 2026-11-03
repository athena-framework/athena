# Represents a user of the application, as loaded by an `ASEC::User::Provider::Interface`.
#
# Regardless of where users come from, e.g. a database or configuration, the type representing them includes this module, which is all the security component needs to know about them.
#
# ```
# class User
#   include ASEC::User::Interface
#
#   getter email : String
#
#   def initialize(@email : String); end
#
#   def roles : Array(String)
#     ["ROLE_USER"]
#   end
#
#   def user_identifier : String
#     @email
#   end
# end
# ```
#
# Users that log in with a password also include [APH::PasswordAuthenticatedUserInterface](/PasswordHasher/PasswordAuthenticatedUserInterface/).
module Athena::Security::User::Interface
  # Returns the roles granted to this user, e.g. `["ROLE_USER"]`.
  abstract def roles : Array(String)

  # Returns the identifier of this user, e.g. its username or email address.
  #
  # The identifier must not be empty.
  abstract def user_identifier : String
end
