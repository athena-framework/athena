# An `ASEC::Exception::AccountStatus` whose message is shown to the user.
#
# WARNING: Make sure the message is safe to show to users, e.g. do not pass the message of another exception.
class Athena::Security::Exception::CustomUserMessageAccountStatus < Athena::Security::Exception::AccountStatus
  # :inherit:
  getter message_key : String = ""

  # :inherit:
  getter message_data : Hash(String, String) = {} of String => String

  def initialize(message : String = "", message_data : Hash(String, String) = {} of String => String, cause : ::Exception? = nil, *, user : ASEC::User::Interface? = nil)
    super message, cause, user: user

    self.set_safe_message message, message_data
  end

  # Sets the *message_key* shown to users, and the *message_data* to interpolate into it.
  def set_safe_message(message_key : String, message_data : Hash(String, String) = {} of String => String) : Nil
    @message_key = message_key
    @message_data = message_data
  end
end
