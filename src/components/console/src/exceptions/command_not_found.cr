require "./console_exception"

class Athena::Console::Exceptions::CommandNotFound < Athena::Console::Exceptions::ConsoleException
  getter alternatives : Array(String)

  def initialize(message : String, @alternatives : Array(String) = [] of String, code : Int32 = 0, cause : Exception? = nil)
    super message, code, cause
  end
end
