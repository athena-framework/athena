class Athena::Console::Descriptor::Context
  property format : String
  property? raw_text : Bool
  property? raw_output : Bool?
  property namespace : String?
  property total_width : Int32?
  property? short : Bool

  def initialize(
    @format : String = "txt",
    @raw_text : Bool = false,
    @raw_output : Bool? = nil,
    @namespace : String? = nil,
    @total_width : Int32? = nil,
    @short : Bool = false,
  )
  end

  def_clone
end
