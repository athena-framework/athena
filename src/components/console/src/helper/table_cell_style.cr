struct Athena::Console::Helper::Table::CellStyle
  enum Align
    LEFT
    RIGHT
    CENTER
  end

  getter foreground : String
  getter background : String
  getter align : Align
  getter format : String?

  def initialize(
    @foreground : String = "default",
    @background : String = "default",
    @align : ACON::Helper::Table::CellStyle::Align = :left,
    @format : String? = nil
  )
  end

  def tag : String
    "fg=#{@foreground};bg=#{@background}"
  end

  protected def pad(string : String, width : Int32, padding_char) : String
    case @align
    in .left?   then string.ljust width, padding_char
    in .right?  then string.rjust width, padding_char
    in .center? then string.center width, padding_char
    end
  end
end
