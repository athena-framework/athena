# The base type of authentication exceptions caused by the status of a user's account, e.g. it being disabled.
#
# Typically raised by an `ASEC::User::Checker::Interface`.
abstract class Athena::Security::Exception::AccountStatus < Athena::Security::Exception::Authentication
  # The user whose account was rejected, if any.
  property user : ASEC::User::Interface?

  def initialize(message : String? = nil, cause : ::Exception? = nil, *, @user : ASEC::User::Interface? = nil)
    super message, cause
  end
end
