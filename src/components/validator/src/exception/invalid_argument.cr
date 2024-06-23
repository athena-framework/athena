# Represents a code logic error that should lead directly to a fix in your code.
class Athena::Validator::Exception::InvalidArgument < ArgumentError
  include Athena::Validator::Exception
end
