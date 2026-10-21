# Allows a user to choose the name of the password hasher used for its password, instead of the one configured for its type.
#
# ```
# class User
#   include APH::PasswordAuthenticatedUserInterface
#   include APH::PasswordHasherAwareInterface
#
#   getter password : String?
#
#   def initialize(@password : String?, @admin : Bool = false); end
#
#   def password_hasher_name : String?
#     # Use a stronger hasher for admins, and the default one for everyone else.
#     @admin ? "admin" : nil
#   end
# end
#
# factory = APH::Factory.new({
#   User    => APH::Native.new,
#   "admin" => APH::Native.new(cost: 15),
# })
# ```
module Athena::PasswordHasher::PasswordHasherAwareInterface
  # Returns the name of the password hasher to use, or `nil` to use the one configured for the type of this user.
  abstract def password_hasher_name : String?
end
