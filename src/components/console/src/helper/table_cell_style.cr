# Represents the styling for a specific `ACON::Helper::Table::Cell`.
struct Athena::Console::Helper::Table::CellStyle
  # Returns the foreground color for this cell.
  #
  # Can be any color string supported via [ACON::Formatter::OutputStyleInterface][Athena::Console::Formatter::OutputStyleInterface--inline-styles],
  # e.g. named (`"red"`) or hexadecimal (`"#38bdc2"`) colors.
  getter foreground : String

  # Returns the background color for this cell.
  #
  # Can be any color string supported via [ACON::Formatter::OutputStyleInterface][Athena::Console::Formatter::OutputStyleInterface--inline-styles],
  # e.g. named (`"red"`) or hexadecimal (`"#38bdc2"`) colors.
  getter background : String

  # How the text should be aligned in the cell.
  #
  # See `ACON::Helper::Table::Alignment`.
  getter align : ACON::Helper::Table::Alignment

  # A `sprintf` format string representing the content of the cell.
  # Should have a single `%s` representing the cell's value.
  #
  # Can be used to reuse [custom style tags][Athena::Console::Formatter::OutputStyleInterface--custom-styles].
  # E.g. `"<fire>%s</>"`.
  getter format : String?

  def initialize(
    @foreground : String = "default",
    @background : String = "default",
    @align : ACON::Helper::Table::Alignment = :left,
    @format : String? = nil,
  )
  end

  protected def tag : String
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
