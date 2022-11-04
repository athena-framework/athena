struct Athena::Console::Helper::Table::CellStyle
  enum Align
    DEFAULT
    LEFT
    RIGHT
    BOTH
  end

  enum Pad
    LEFT
    RIGHT
    BOTH
  end

  getter foreground : String
  getter background : String
  getter align : ACON::Helper::Table::CellStyle::Align
  getter format : String?

  def initialize(
    @foreground : String = "default",
    @background : String = "default",
    @align : ACON::Helper::Table::CellStyle::Align = :default,
    @format : String? = nil
  )
  end

  def pad_type : ACON::Helper::Table::CellStyle::Pad
    case @align
    in .left?, .default? then :right
    in .right?           then :left
    in .center?          then :both
    end
  end
end
