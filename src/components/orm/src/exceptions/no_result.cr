require "./unexpected_result"

# Raised when exactly one result is required but none was found.
#
# For example by `AORM::EntityManager#find!`, `AORM::EntityRepository#find!` and `AORM::NativeQuery#get_single_result`.
class Athena::ORM::Exceptions::NoResult < Athena::ORM::Exceptions::UnexpectedResult
  def initialize
    super "No result was found"
  end
end
