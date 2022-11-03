class Athena::Console::Helper::Table
  enum Orientation
    DEFAULT
    HORIZONTAL
    VERTICAL
  end

  alias RowType = Enumerable(String | ACON::Helper::Table::Cell::Seperator)
  alias CellType = ACON::Helper::Table::Cell | String

  setter header_title : String? = nil
  setter footer_title : String? = nil

  @headers = [] of String
  @rows = [] of RowType

  @effective_column_widths = [] of Int32
  @number_of_columns : Int32? = nil
  property style : ACON::Helper::Table::Style
  @column_styles = Hash(Int32, ACON::Helper::Table::Style).new
  @column_widths = Hash(Int32, Int32).new
  @column_max_widths = Hash(Int32, Int32).new
  @rendered = false
  @orientation : Orientation = :default

  @output : ACON::Output::Interface

  @@styles : Hash(String, ACON::Helper::Table::Style)? = nil

  def self.set_style_definition(name : String, style : ACON::Helper::Table::Style) : Nil
    @@styles ||= init_styles

    @@styles[name] = style
  end

  def self.style_definition(name : String) : ACON::Helper::Table::Style
    @@styles ||= init_styles

    @@styles[style]? || raise ACON::Exceptions::InvalidArgument.new "The table style '#{style}' is not defined."
  end

  protected def self.init_styles : Hash(String, ACON::Helper::Table::Style)
    {
      "default" => ACON::Helper::Table::Style.new,
    }
  end

  def initialize(@output : ACON::Output::Interface)
    @@styles ||= self.class.init_styles

    @style = ACON::Helper::Table::Style.new
  end

  def column_style(index : Int32, style : ACON::Helper::Table::Style | String) : self
    @column_styles[index] = self.resolve_style style

    self
  end

  def column_style(index : Int32) : ACON::Helper::Table::Style
    @column_styles[index]? || self.style
  end

  def column_width(index : Int32, width : Int32) : self
    @column_widths[index] = width

    self
  end

  def column_width(widths : Enumerable(Int32)) : self
    @column_widths.clear

    widths.each_with_index do |w, idx|
      self.column_width idx, w
    end

    self
  end

  def scolumn_max_width(index : Int32, width : Int32) : self
    if !@output.formatter.is_a? ACON::Formatter::WrappableInterface
      raise ACON::Exceptions::Logic.new "Setting a maximum column width is only supported when using a #{ACON::Formatter::WrappableInterface} formatter, got #{@output.class}"
    end

    @column_max_widths[index] = width

    self
  end

  def headers(headers : Enumerable(String)) : self
    @headers = headers.to_a

    self
  end

  def rows(rows : Enumerable(RowType)) : self
    @rows.clear

    self.add_rows rows
  end

  def add_rows(rows : Enumerable(RowType)) : self
    rows.each do |r|
      self.add_row r
    end

    self
  end

  def add_row(row : RowType) : self
    @rows << row

    self
  end

  def append_row(row : RowType) : self
    if !@output.is_a? ACON::Output::Section
      raise ACON::Exceptions::Logic.new "Appending a row is only supported when using a #{ACON::Output::Section} output, got #{@output.class}"
    end

    if @rendered
      @output.clear self.calculate_row_count
    end

    self.add_row row
    self.render

    self
  end

  def row(index : Int32, row : RowType) : self
    @rows[index] = row

    self
  end

  def horizontal : self
    @orientation = :horizontal

    self
  end

  def vertical : self
    @orientation = :vertical

    self
  end

  def render : Nil
    divider = ACON::Helper::Table::Cell::Seperator.new
    is_cell_with_colspan = ->(cell : CellType) { cell.is_a?(ACON::Helper::Table::Cell) && cell.colspan >= 2 }

    rows = [] of String

    if @orientation.horizontal?
      (@headers[0]? || Tuple.new).each_with_index do |header, idx|
        rows[idx] = [header]
      end
    elsif @orientation.vertical?
    else
    end
  end

  private def resolve_style(style : ACON::Helper::Table::Style) : ACON::Helper::Table::Style
    style
  end

  private def resolve_style(style : String) : ACON::Helper::Table::Style
    @@styles[style]? || raise ACON::Exceptions::InvalidArgument.new "The table style '#{style}' is not defined."
  end
end
