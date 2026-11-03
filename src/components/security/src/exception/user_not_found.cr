# Raised when no user exists for a given identifier.
class Athena::Security::Exception::UserNotFound < Athena::Security::Exception::Authentication
  # The identifier of the user that could not be found, e.g. a username or email address.
  property user_identifier : String?

  def initialize(message : String? = nil, cause : ::Exception? = nil, *, @user_identifier : String? = nil)
    super message, cause
  end

  # :inherit:
  def message_key : String
    "Username could not be found."
  end

  # :inherit:
  def message_data : Hash(String, String)
    user_identifier = @user_identifier || ""

    {"{{ username }}" => user_identifier, "{{ user_identifier }}" => user_identifier}
  end
end
