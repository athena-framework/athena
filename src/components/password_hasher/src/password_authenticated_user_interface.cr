# Represents a user whose password is hashed with an `APH::Interface`.
#
# ```
# class User
#   include APH::PasswordAuthenticatedUserInterface
#
#   getter password : String?
#
#   def initialize(@password : String? = nil); end
# end
# ```
module Athena::PasswordHasher::PasswordAuthenticatedUserInterface
  # Returns the hashed password of this user, if any.
  abstract def password : String?
end
