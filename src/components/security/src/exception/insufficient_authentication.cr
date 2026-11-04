# Raised when the authentication of a user is not trusted enough to access a resource, e.g. because no user is authenticated.
class Athena::Security::Exception::InsufficientAuthentication < Athena::Security::Exception::Authentication
  # :inherit:
  def message_key : String
    "Not privileged to request the resource."
  end
end
