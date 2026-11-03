# Checks the status of a user's account while it is being authenticated, e.g. whether it is disabled or locked.
#
# Checkers should be cheap and free of side effects, as they run on every authentication, and not only when the user logs in.
# They reject a user by raising an `ASEC::Exception::AccountStatus`, and should not be used to make authentication decisions.
#
# ```
# class UserChecker
#   include ASEC::User::Checker::Interface
#
#   def check_pre_auth(user : ASEC::User::Interface) : Nil
#     return unless user.is_a? User
#
#     raise ASEC::Exception::CustomUserMessageAccountStatus.new "Your account was banned.", user: user if user.banned?
#   end
#
#   def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil
#   end
# end
# ```
module Athena::Security::User::Checker::Interface
  # Checks the account of the provided *user* before its credentials are checked.
  #
  # Raises an `ASEC::Exception::AccountStatus` if the *user* is rejected.
  abstract def check_pre_auth(user : ASEC::User::Interface) : Nil

  # Checks the account of the provided *user* after it was authenticated, optionally with the *token* representing it.
  #
  # Raises an `ASEC::Exception::AccountStatus` if the *user* is rejected.
  abstract def check_post_auth(user : ASEC::User::Interface, token : ASEC::Authentication::Token::Interface? = nil) : Nil
end
