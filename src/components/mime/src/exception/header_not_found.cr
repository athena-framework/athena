# Raised when trying to retrieve a header by name, but there are no headers with that name.
class Athena::MIME::Exception::HeaderNotFound < ::KeyError
  include Athena::MIME::Exception
end
