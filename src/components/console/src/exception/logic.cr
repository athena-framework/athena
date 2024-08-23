# Represents a code logic error that should lead directly to a fix in your code.
class Athena::Console::Exception::Logic < ::Exception
  include Athena::Console::Exception

  def initialize(message : String, @code : Int32 = 0, cause : ::Exception? = nil)
    super message, cause
  end
end
