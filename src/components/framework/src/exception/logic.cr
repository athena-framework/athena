class LogicError < ::Exception; end

# Represents a code logic error that should lead directly to a fix in your code.
class Athena::Framework::Exception::Logic < LogicError
  include Athena::Framework::Exception
end
