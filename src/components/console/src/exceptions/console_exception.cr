# Base class of all `ACON::Exceptions`.
#
# Exposes a `#code` method that represents the exit code of a command invocation.
abstract class Athena::Console::Exceptions::ConsoleException < ::Exception
  # Returns the code to use as the exit status of a command invocation.
  getter code : Int32

  def initialize(message : String, @code : Int32 = 1, cause : Exception? = nil)
    super message, cause
  end
end
