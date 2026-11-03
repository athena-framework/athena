# Raised when the current user is not granted access, e.g. because it lacks a required role.
class Athena::Security::Exception::AccessDenied < RuntimeError
  include Athena::Security::Exception

  # The attribute that was denied, if any.
  property attribute : String? = nil

  # The decision that denied the access, if any, which explains it.
  property access_decision : ASEC::Authorization::AccessDecision? = nil

  def initialize(message : String = "Access Denied.", cause : ::Exception? = nil)
    super message, cause
  end
end
