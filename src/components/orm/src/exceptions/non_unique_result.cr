require "./unexpected_result"

# Raised when at most one result is expected but the query returned more.
#
# For example by `AORM::NativeQuery#get_single_result` and `AORM::NativeQuery#get_one_or_nil_result`.
class Athena::ORM::Exceptions::NonUniqueResult < Athena::ORM::Exceptions::UnexpectedResult
  def initialize
    super "More than one result was found"
  end
end
