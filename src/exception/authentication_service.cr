# Raised when an authentication could not be processed due to a system problem.
class Athena::Security::Exception::AuthenticationService < Athena::Security::Exception::Authentication
  # :inherit:
  def message_key : String
    "Authentication request could not be processed due to a system problem."
  end
end
