# Raised when an `ASEC::User::Provider::Interface` is given a user it does not support.
class Athena::Security::Exception::UnsupportedUser < Athena::Security::Exception::AuthenticationService
end
