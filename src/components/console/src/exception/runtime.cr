class Athena::Console::Exception::Runtime < RuntimeError
  include Athena::Console::Exception

  def initialize(message : String, @code : Int32 = 0, cause : ::Exception? = nil)
    super message, cause
  end
end
