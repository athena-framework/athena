# Raised when the credentials of a user are invalid, e.g. a wrong password.
class Athena::Security::Exception::BadCredentials < Athena::Security::Exception::Authentication
  # :inherit:
  def message_key : String
    "Invalid credentials."
  end
end
