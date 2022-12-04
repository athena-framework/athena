require "./validator_error"

# Represents a code logic error that should lead directly to a fix in your code.
class Athena::Validator::Exceptions::Logic < Athena::Validator::Exceptions::ValidatorError
end
