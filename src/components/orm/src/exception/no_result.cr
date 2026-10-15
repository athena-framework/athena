require "./unexpected_result"

# Raised when exactly one result is required but none was found.
#
# For example by `AORM::NativeQuery#get_single_result`.
class Athena::ORM::Exception::NoResult < Athena::ORM::Exception::UnexpectedResult
  def initialize
    super "No result was found for query although at least one row was expected."
  end
end
