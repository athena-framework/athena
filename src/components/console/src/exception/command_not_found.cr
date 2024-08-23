class Athena::Console::Exception::CommandNotFound < ArgumentError
  include Athena::Console::Exception

  getter alternatives : Array(String)

  def initialize(message : String, @alternatives : Array(String) = [] of String, @code : Int32 = 0)
    super message
  end
end
