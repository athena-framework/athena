record Athena::Console::Descriptor::Context,
  format : String = "txt",
  raw_text : Bool = false,
  raw_output : Bool? = nil,
  namespace : String? = nil,
  total_width : Int32? = nil,
  short : Bool = false do
  def raw_text? : Bool
    @raw_text
  end

  def raw_output? : Bool?
    @raw_output
  end

  def short? : Bool
    @short
  end
end
