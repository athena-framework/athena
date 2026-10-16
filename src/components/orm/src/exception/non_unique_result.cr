require "./unexpected_result"

# Raised when at most one result is expected but the query returned more.
#
# For example by `AORM::NativeQuery#get_single_result` and `AORM::NativeQuery#get_one_or_nil_result`.
class Athena::ORM::Exception::NonUniqueResult < Athena::ORM::Exception::UnexpectedResult
  def initialize(message : String = "More than one result was found for query although one row or none was expected.")
    super message
  end
end
