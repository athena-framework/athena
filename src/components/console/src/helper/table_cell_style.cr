struct Athena::Console::Helper::Table::CellStyle
  enum Align
    DEFAULT
    LEFT
    RIGHT
    BOTH
  end

  getter foreground : String
  getter background : String
  getter align : Align
  getter format : String?

  def initialize(
    @foreground : String = "default",
    @background : String = "default",
    @align : ACON::Helper::Table::CellStyle::Align = :default,
    @format : String? = nil
  )
  end

  protected def pad(string : String, width : Int32, padding_char) : String
    case @align
    in .left?, .default? then string.rjust width, padding_char
    in .right?           then string.ljust width, padding_char
    in .center?          then string.center width, padding_char
    end
  end
end
