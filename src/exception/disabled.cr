# Raised when the account of a user is disabled.
class Athena::Security::Exception::Disabled < Athena::Security::Exception::AccountStatus
  # :inherit:
  def message_key : String
    "Account is disabled."
  end
end
