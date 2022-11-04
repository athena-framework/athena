class Athena::Console::Helper::Table
  enum Orientation
    DEFAULT
    HORIZONTAL
    VERTICAL
  end

  record Athena::Console::Helper::Table::Cell, value : String = "", rowspan : Int32 = 1, colspan : Int32 = 1, style : ACON::Helper::Table::CellStyle? = nil do
    def to_s(io : IO) : Nil
      io << @value
    end
  end

  record Athena::Console::Helper::Table::TableSeperator, rowspan : Int32 = 1, colspan : Int32 = 1, style : ACON::Helper::Table::CellStyle? = nil do
    def to_s(io : IO) : Nil
      io << @value
    end
  end

  alias CellType = String | Int64 | Float64 | Bool | Athena::Console::Helper::Table::Cell
  alias RowType = Enumerable(CellType) | Athena::Console::Helper::Table::TableSeperator

  private struct Row
    alias Type = String | Athena::Console::Helper::Table::Cell

    include Enumerable(Type)

    @columns : Array(Type)

    def self.new(columns : Enumerable(CellType))
      new columns.map { |c| c.is_a?(Athena::Console::Helper::Table::Cell) ? c : c.to_s }
    end

    def initialize(columns : Enumerable(Type))
      @columns = columns.to_a.map &.as Type
    end

    def each(& : Type ->) : Nil
      @columns.each do |c|
        yield c
      end
    end
  end

  # OPTIMIZE: Can this be merged into `Row`?
  private struct Rows
    alias Type = Athena::Console::Helper::Table::TableSeperator | Array(Row::Type)

    include Enumerable(Type)

    @columns : Array(Array(Type))

    def initialize(@columns : Array(Array(Type))); end

    def each(& : Array(Type) ->) : Nil
      @columns.each do |c|
        yield c
      end
    end
  end

  setter header_title : String? = nil
  setter footer_title : String? = nil

  @headers = [] of Array(String)
  @rows = Array(Row).new

  @effective_column_widths = Hash(Int32, Int32).new
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
    @headers = [headers.to_a]

    self
  end

  # Overrides the rows of this table to those provided in *rows*.
  def rows(rows : Enumerable(RowType)) : self
    @rows.clear

    self.add_rows rows
  end

  # Adds n new rows
  def add_rows(rows : Enumerable(RowType)) : self
    rows.each do |r|
      self.add_row r
    end

    self
  end

  def add_row(*columns : CellType) : self
    self.add_row columns

    self
  end

  # Adds a single new row
  def add_row(row : Athena::Console::Helper::Table::Cell) : self
    @rows << row

    self
  end

  def add_row(row : RowType) : self
    @rows << Row.new row

    self
  end

  # def append_row(row : RowType) : self
  #   if !@output.is_a? ACON::Output::Section
  #     raise ACON::Exceptions::Logic.new "Appending a row is only supported when using a #{ACON::Output::Section} output, got #{@output.class}"
  #   end

  #   if @rendered
  #     @output.clear self.calculate_row_count
  #   end

  #   self.add_row row
  #   self.render

  #   self
  # end

  #
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

  private alias InternalRowType = Row | ACON::Helper::Table::TableSeperator

  def render
    divider = ACON::Helper::Table::TableSeperator.new
    is_cell_with_colspan = ->(cell : CellType) { cell.is_a?(ACON::Helper::Table::Cell) && cell.colspan >= 2 }

    rows = Array(InternalRowType).new

    if @orientation.horizontal?
      # (@headers[0]? || Array(String).new).each_with_index do |header, idx|
      #   rows[idx] = [header].as RowType

      #   @rows.each do |row|
      #     next if row.is_a? ACON::Helper::Table::TableSeperator

      #     if r = row[idx]?
      #       rows[idx].as(Enumerable(CellType)) << r
      #     elsif is_cell_with_colspan.call(rows[idx].first)
      #     else
      #       rows[idx] << ACON::Helper::Table::Cell::Value.new ""
      #     end
      #   end
      # end
    elsif @orientation.vertical?
    else
      @headers.each { |h| rows << Row.new h }
      rows << divider
      @rows.each { |h| rows << Row.new h }
    end

    self.calculate_number_of_columns rows

    row_groups = self.build_table_rows rows
    self.calculate_columns_width row_groups

    is_header = !@orientation.horizontal?
    is_first_row = @orientation.horizontal?
    has_title = !!@header_title.presence

    row_groups.each do |row_group|
      is_header_separator_rendered : Bool = false

      row_group.each do |row|
        if divider == row
          is_header = false
          is_first_row = true

          next
        end

        if row.is_a? TableSeperator
          self.render_row_separator

          next
        end

        # TODO: Handle empty/nil rows?

        if is_header && !is_header_separator_rendered
          self.render_row_separator(
            is_header ? Separator::TOP : Separator::TOP_BOTTOM,
            has_title ? @header_title : nil,
            has_title ? @style.header_title_format : nil
          )

          has_title = false
          is_header_separator_rendered = true
        end

        if is_first_row
          self.render_row_separator(
            is_header ? Separator::TOP : Separator::TOP_BOTTOM,
            has_title ? @header_title : nil,
            has_title ? @style.header_title_format : nil
          )

          is_first_row = false
          has_title = false
        end

        if @orientation.vertical?
          is_header = false
          is_first_row = false
        end

        if @orientation.horizontal?
          self.render_row row, @style.cell_row_format, @style.cell_header_format
        else
          self.render_row row, is_header ? @style.cell_header_format : @style.cell_row_format
        end
      end
    end

    self.render_row_separator :bottom, @footer_title, @style.footer_title_format

    # self.cleanup
    @rendered = true
  end

  private def build_table_rows(rows : Array(InternalRowType)) : Rows
    formatter = @output.formatter.as ACON::Formatter::WrappableInterface

    unmerged_rows = [] of String

    rows.size.times do |row_key|
      rows = self.fill_next_rows rows, row_key

      # Remove any line breaks and replace it with a new line
      self.iterate_row(rows, row_key) do |cell, column|
        cell_value = cell.to_s

        colspan = cell.is_a?(ACON::Helper::Table::Cell) ? cell.colspan : 1

        if (max_width = @column_max_widths[column]?) && (Helper.width(Helper.remove_decoration(formatter, cell_value)) > max_width)
          cell_value = formatter.format_and_wrap cell_value, max_width * colspan
        end

        next unless cell_value.includes? '\n'

        raise "Cell contained new line"
      end
    end

    row_groups = [] of Array(Rows::Type)

    rows.each_with_index do |row, row_key|
      row_group = [row.is_a?(ACON::Helper::Table::TableSeperator) ? row : self.fill_cells(row)] of Rows::Type

      # TODO: Handle unmerged rows

      row_groups << row_group
    end

    Rows.new row_groups
  end

  # Fills rows that contain rowspan > 1
  private def fill_next_rows(rows : Enumerable, line : Int32) : Enumerable
    unmerged_rows = [] of String

    self.iterate_row(rows, line) do |cell, column|
      if cell.is_a?(ACON::Helper::Table::Cell) && cell.rowspan > 1
        raise "Rowspan > 1"
      end
    end

    unmerged_rows.each_with_index do |unmerged_row, unmerged_row_key|
      raise ">1 unmerged row"
    end

    rows
  end

  # Fills cells for a colspan > 1
  private def fill_cells(row : Row) : Array(Row::Type)
    new_row = [] of String | ACON::Helper::Table::Cell

    row.each_with_index do |cell, column|
      new_row << cell

      if cell.is_a?(ACON::Helper::Table::Cell) && cell.colspan > 1
        raise "Colspan > 1"
      end
    end

    new_row.empty? ? row.to_a : new_row
  end

  private def calculate_number_of_columns(rows : Enumerable) : Nil
    columns = [0]

    rows.each do |row|
      next if row.is_a? ACON::Helper::Table::TableSeperator

      columns << self.get_number_of_columns row
    end

    @number_of_columns = columns.max
  end

  private def calculate_columns_width(groups : Rows) : Nil
    @number_of_columns.not_nil!.times do |column|
      lengths = [] of Int32

      groups.each do |group|
        group.each do |row|
          next if row.is_a? ACON::Helper::Table::TableSeperator

          row.each_with_index do |cell, idx|
            if cell.is_a? ACON::Helper::Table::Cell
              raise "cell was table cell"
            end

            lengths << self.get_cell_width row, column
          end
        end
      end

      @effective_column_widths[column] = lengths.max + Helper.width(@style.cell_row_content_format) - 2
    end
  end

  private def get_cell_width(row : Rows::Type, column : Int32) : Int32
    cell_width = 0

    if cell = row[column]?
      cell_width = Helper.width Helper.remove_decoration @output.formatter, cell.to_s
    end

    column_width = @column_widths[column]? || 0
    cell_width = Math.max cell_width, column_width

    (max_width = @column_max_widths[column]?) ? Math.min(max_width, cell_width) : cell_width
  end

  private def get_number_of_columns(row : Enumerable) : Int32
    columns = row.size

    row.each do |column|
      columns += column.is_a?(ACON::Helper::Table::Cell) ? column.colspan - 1 : 0
    end

    columns
  end

  private enum Separator
    TOP
    TOP_BOTTOM
    MIDDLE
    BOTTOM
  end

  private def render_row_separator(type : Separator = :middle, title : String? = nil, title_format : String? = nil) : Nil
    return unless (count = @number_of_columns)

    borders = @style.border_chars

    if !borders[0].presence && !borders[2].presence && !@style.crossing_char.presence
      return
    end

    crossings = @style.crossing_chars
    horizontal, left_char, middle_char, right_char = case type
                                                     when .middle?     then {borders[2], crossings[8], crossings[0], crossings[4]}
                                                     when .top?        then {borders[0], crossings[1], crossings[2], crossings[3]}
                                                     when .top_bottom? then {borders[0], crossings[9], crossings[10], crossings[11]}
                                                     else
                                                       {borders[0], crossings[7], crossings[6], crossings[5]}
                                                     end

    markup = String.build do |io|
      io << left_char

      count.times do |column|
        io << horizontal * @effective_column_widths[column]
        io << ((column == (count - 1)) ? right_char : middle_char)
      end

      unless title.nil?
        raise "Title was not nil"
      end
    end

    @output.puts sprintf @style.border_format, markup
  end

  private def render_row(row : Rows::Type, cell_format : String, first_cell_format : String? = nil) : Nil
    columns = self.get_row_columns row
    last = columns.size - 1

    markup = String.build do |io|
      io << self.render_column_separator :outside

      columns.each_with_index do |column, idx|
        io << if first_cell_format && idx.zero?
          self.render_cell row, column, first_cell_format
        else
          self.render_cell row, column, cell_format
        end

        io << self.render_column_separator last == idx ? Border::OUTSIDE : Border::INSIDE
      end
    end

    @output.puts markup
  end

  private def render_cell(row : Rows::Type, column : Int32, cell_format : String) : String
    cell = (row[column]? || "").to_s
    width = @effective_column_widths[column]

    if cell.is_a? Cell && cell.colspan > 1
      raise "Colspan > 1"
    end

    # TODO: Handle multi-byte strings?

    style = self.get_column_style column

    if cell.is_a? TableSeperator
      return sprintf style.border_format, style.border_chars[2] * width
    end

    width += cell.size - Helper.remove_decoration(@output.formatter, cell).size
    content = sprintf style.cell_row_content_format, cell

    if cell.is_a?(Cell) && cell.style.is_a?(CellStyle)
      raise "Cell is table cell"
    end

    sprintf cell_format, style.pad content, width, style.padding_char
  end

  private def get_row_columns(row : Rows::Type) : Array(Int32)
    columns = (0...@number_of_columns).to_a

    row.each_with_index do |cell, cell_key|
      if cell.is_a? ACON::Helper::Table::Cell
        raise "Cell is table cell"
      end
    end

    columns
  end

  private enum Border
    OUTSIDE
    INSIDE
  end

  private def render_column_separator(type : Border = :outside) : String
    borders = @style.border_chars

    sprintf @style.border_format, type.outside? ? borders[1] : borders[3]
  end

  # Helper method that allows iterating over the cells of a row, skipping cell seperators
  private def iterate_row(rows : Enumerable, line : Int32, & : String | ACON::Helper::Table::Cell, Int32 ->) : Nil
    columns = rows[line]

    return if columns.is_a? ACON::Helper::Table::TableSeperator

    columns.each_with_index do |cell, idx|
      yield cell, idx
    end
  end

  private def get_column_style(column : Int32) : Style
    @column_styles[column]? || @style
  end

  private def resolve_style(style : ACON::Helper::Table::Style) : Style
    style
  end

  private def resolve_style(style : String) : Style
    @@styles[style]? || raise ACON::Exceptions::InvalidArgument.new "The table style '#{style}' is not defined."
  end
end
