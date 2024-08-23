class Athena::Console::Exception::InvalidOption < ArgumentError
  include Athena::Console::Exception

  def initialize(message : String, @code : Int32 = 0)
    super message
  end
end
