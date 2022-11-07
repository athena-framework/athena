class Athena::Console::Helper::Table
  enum Orientation
    DEFAULT
    HORIZONTAL
    VERTICAL
  end

  class Cell
    getter rowspan : Int32
    getter colspan : Int32
    getter style : Table::CellStyle?

    @value : String

    def initialize(
      value : _ = "",
      @rowspan : Int32 = 1,
      @colspan : Int32 = 1,
      @style : Table::CellStyle? = nil
    )
      @value = value.to_s
    end

    def to_s(io : IO) : Nil
      io << @value
    end
  end

  class Separator < Table::Cell
    def initialize(
      rowspan : Int32 = 1,
      colspan : Int32 = 1,
      style : Table::CellStyle? = nil
    )
      super "", rowspan, colspan, style
    end
  end

  alias CellType = String | Int64 | Int32 | Float32 | Float64 | Bool | Athena::Console::Helper::Table::Cell
  alias RowType = Enumerable(CellType) | Table::Separator

  private struct Row
    alias Type = String | Table::Cell

    include Indexable::Mutable(Type)

    delegate :insert, :<<, :[], to: @columns

    @columns : Array(Type)

    def self.new(columns : Enumerable(CellType))
      new columns.map { |c| c.is_a?(Athena::Console::Helper::Table::Cell) ? c : c.to_s }
    end

    def initialize(columns : Enumerable(Type))
      @columns = columns.to_a.map &.as Type
    end

    def size : Int
      @columns.size
    end

    def unsafe_fetch(index : Int) : Type
      @columns[index]
    end

    def unsafe_put(index : Int, value : Type) : Nil
      @columns[index] = value
    end

    def each(& : Type ->) : Nil
      @columns.each do |c|
        yield c
      end
    end
  end

  # OPTIMIZE: Can this be merged into `Row`?
  private struct Rows
    alias Type = Table::Separator | Array(Row::Type)

    include Enumerable(Type)

    @columns : Array(Array(Type))

    def initialize(@columns : Array(Array(Type))); end

    def each(& : Array(Type) ->) : Nil
      @columns.each do |c|
        yield c
      end
    end
  end

  # INTERNAL
  protected class_getter styles : Hash(String, ACON::Helper::Table::Style) { self.init_styles }

  def self.set_style_definition(name : String, style : ACON::Helper::Table::Style) : Nil
    self.styles[name] = style
  end

  def self.style_definition(name : String) : ACON::Helper::Table::Style
    self.styles[name]? || raise ACON::Exceptions::InvalidArgument.new "The table style '#{name}' is not defined."
  end

  # INTERNAL
  private def self.init_styles : Hash(String, ACON::Helper::Table::Style)
    borderless = Table::Style.new
    borderless
      .horizontal_border_chars("=")
      .vertical_border_chars(" ")
      .default_crossing_char(" ")

    compact = Table::Style.new
    compact
      .horizontal_border_chars("")
      .vertical_border_chars("")
      .default_crossing_char("")
      .cell_row_content_format("%s ")

    suggested = Table::Style.new
    suggested
      .horizontal_border_chars("-")
      .vertical_border_chars(" ")
      .default_crossing_char(" ")
      .cell_header_format("%s")

    box = Table::Style.new
    box
      .horizontal_border_chars("─")
      .vertical_border_chars("│")
      .crossing_chars("┼", "┌", "┬", "┐", "┤", "┘", "┴", "└", "├")

    double_box = Table::Style.new
    double_box
      .horizontal_border_chars("═", "─")
      .vertical_border_chars("║", "│")
      .crossing_chars("┼", "╔", "╤", "╗", "╢", "╝", "╧", "╚", "╟", "╠", "╪", "╣")

    {
      "borderless" => borderless,
      "compact"    => compact,
      "suggested"  => suggested,
      "box"        => box,
      "double-box" => double_box,
      "default"    => ACON::Helper::Table::Style.new,
    }
  end

  @header_title : String? = nil
  @footer_title : String? = nil

  @headers = Array(Row).new
  @rows = Array(Row | Table::Separator).new

  @effective_column_widths = Hash(Int32, Int32).new
  @number_of_columns : Int32? = nil
  getter style : ACON::Helper::Table::Style
  @column_styles = Hash(Int32, ACON::Helper::Table::Style).new
  @column_widths = Hash(Int32, Int32).new
  @column_max_widths = Hash(Int32, Int32).new
  @rendered = false
  @orientation : Orientation = :default

  @output : ACON::Output::Interface

  def initialize(@output : ACON::Output::Interface)
    @style = ACON::Helper::Table::Style.new
  end

  def header_title(@header_title : String?) : self
    self
  end

  def footer_title(@footer_title : String?) : self
    self
  end

  def style(name : String | ACON::Helper::Table::Style) : self
    @style = self.resolve_style name

    self
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

  def column_widths(widths : Enumerable(Int32)) : self
    @column_widths.clear

    widths.each_with_index do |w, idx|
      self.column_width idx, w
    end

    self
  end

  def column_widths(*widths : Int32) : self
    self.column_widths widths
  end

  def column_max_width(index : Int32, width : Int32) : self
    if !@output.formatter.is_a? ACON::Formatter::WrappableInterface
      raise ACON::Exceptions::Logic.new "Setting a maximum column width is only supported when using a #{ACON::Formatter::WrappableInterface} formatter, got #{@output.class}."
    end

    @column_max_widths[index] = width

    self
  end

  def headers(*names : CellType) : self
    self.headers names
  end

  def headers(headers : RowType) : self
    self.headers({headers})
  end

  def headers(headers : Enumerable(RowType)) : self
    @headers.clear

    headers.each do |h|
      @headers << Row.new h
    end

    self
  end

  # Overrides the rows of this table to those provided in *rows*.
  def rows(rows : RowType) : self
    self.rows({rows})
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

  # Adds a single new row
  def add_row(row : RowType) : self
    @rows << case row
    when Table::Separator then row
    else
      Row.new row
    end

    self
  end

  def add_row(*columns : CellType) : self
    self.add_row columns

    self
  end

  def append_row(row : RowType) : self
    unless (output = @output).is_a? ACON::Output::Section
      raise ACON::Exceptions::Logic.new "Appending a row is only supported when using a #{ACON::Output::Section} output, got #{@output.class}."
    end

    if @rendered
      output.clear self.calculate_row_count
    end

    self.add_row row
    self.render

    self
  end

  def append_row(*columns : CellType) : self
    self.append_row([*columns])
  end

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

  private alias InternalRowType = Row | ACON::Helper::Table::Separator

  private def combined_rows(divider : Table::Separator) : Array(InternalRowType)
    rows = Array(InternalRowType).new
    is_cell_with_colspan = ->(cell : CellType) { cell.is_a?(ACON::Helper::Table::Cell) && cell.colspan >= 2 }

    if @orientation.horizontal?
      @headers[0]?.try &.each_with_index do |header, idx|
        rows.insert idx, Row.new [header]
        @rows.each do |row|
          next if row.is_a? Table::Separator

          if rv = row[idx]?
            rows[idx].as(Row) << rv
          elsif is_cell_with_colspan.call rows[idx].as(Row)[0]
            # Noop, there is a "title"
          else
            rows[idx].as(Row) << ""
          end
        end
      end
    elsif @orientation.vertical?
      formatter = @output.formatter
      max_header_length = (@headers[0]? || [] of String).reduce 0 do |acc, header|
        Math.max acc, Helper.width(Helper.remove_decoration(formatter, header.to_s))
      end

      @rows.each do |row|
        next if row.is_a? Table::Separator

        unless rows.empty?
          rows << Row.new [divider]
        end

        contains_colspan = false

        row.each do |cell|
          if contains_colspan = is_cell_with_colspan.call cell
            break
          end
        end

        headers = @headers[0]? || [] of String
        max_rows = Math.max headers.size, row.size

        max_rows.times do |idx|
          cell = (row[idx]? || "").to_s

          if !headers.empty? && !contains_colspan
            rows << Row.new([
              sprintf(
                "<comment>%s</>: %s",
                headers[idx]?.to_s.rjust(max_header_length, ' '),
                cell
              ),
            ])
          elsif !cell.empty?
            rows << Row.new [cell]
          end
        end
      end
    else
      @headers.each { |h| rows << Row.new h unless h.empty? }
      rows << divider
      @rows.each do |r|
        case r
        when Table::Separator then rows << r
        else
          rows << Row.new r unless r.empty?
        end
      end
    end

    rows
  end

  def render
    divider = ACON::Helper::Table::Separator.new

    rows = self.combined_rows divider

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

        if row.is_a? Table::Separator
          self.render_row_separator

          next
        end

        # TODO: Handle empty/nil rows?

        if is_header && !is_header_separator_rendered
          self.render_row_separator(
            is_header ? RowSeparator::TOP : RowSeparator::TOP_BOTTOM,
            has_title ? @header_title : nil,
            has_title ? @style.header_title_format : nil
          )

          has_title = false
          is_header_separator_rendered = true
        end

        if is_first_row
          self.render_row_separator(
            is_header ? RowSeparator::TOP : RowSeparator::TOP_BOTTOM,
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

    self.cleanup
    @rendered = true
  end

  private def cleanup : Nil
    @effective_column_widths.clear
    @number_of_columns = nil
  end

  private def build_table_rows(rows : Array(InternalRowType)) : Rows
    formatter = @output.formatter.as ACON::Formatter::WrappableInterface

    # row_key => line_key => column idx
    unmerged_rows = Hash(Int32, Hash(Int32, Hash(Int32, String | Table::Cell))).new

    row_key = 0
    while row_key < rows.size
      self.fill_next_rows rows, row_key

      # Remove any line breaks and replace it with a new line
      self.iterate_row(rows, row_key) do |cell, column|
        cell_value = cell.to_s

        colspan = cell.is_a?(ACON::Helper::Table::Cell) ? cell.colspan : 1

        if (max_width = @column_max_widths[column]?) && (Helper.width(Helper.remove_decoration(formatter, cell_value)) > max_width)
          cell_value = formatter.format_and_wrap cell_value, max_width * colspan
        end

        next unless cell_value.includes? '\n'

        escaped = cell_value.split('\n').join '\n' { |v| ACON::Formatter::Output.escape_trailing_backslash v }
        cell = cell.is_a?(Table::Cell) ? Table::Cell.new(escaped, colspan: cell.colspan) : escaped
        cell_value = cell.to_s
        lines = cell_value.gsub('\n', "<fg=default;bg=default></>\n").split '\n'
        lines.each_with_index do |line, line_key|
          if colspan > 1
            line = Table::Cell.new line, colspan: colspan
          end

          if line_key.zero?
            rows[row_key].as(Row)[column] = line
          else
            if !unmerged_rows.has_key?(row_key) || !unmerged_rows[row_key].has_key? line_key
              (unmerged_rows[row_key] ||= Hash(Int32, Hash(Int32, String | Table::Cell)).new)[line_key] = self.copy_row rows, row_key
            end

            unmerged_rows[row_key][line_key][column] = line
          end
        end
      end

      row_key += 1
    end

    row_groups = [] of Array(Rows::Type)

    rows.each_with_index do |row, row_key|
      row_group = [row.is_a?(Table::Separator) ? row : self.fill_cells(row)] of Rows::Type

      if ur = unmerged_rows[row_key]?
        ur.each_value do |row|
          row_group << (row.is_a?(Table::Separator) ? row : self.fill_cells(row))
        end
      end

      row_groups << row_group
    end

    Rows.new row_groups
  end

  # Fills rows that contain rowspan > 1
  private def fill_next_rows(rows : Enumerable, line : Int32) : Nil
    unmerged_rows = Hash(Int32, Hash(Int32, Table::Cell)).new

    self.iterate_row(rows, line) do |cell, column|
      cell_value = cell.to_s

      if cell.is_a?(ACON::Helper::Table::Cell) && cell.rowspan > 1
        nb_lines = cell.rowspan - 1
        lines = [cell_value]

        if cell_value.includes? '\n'
          lines = cell_value.gsub("\n", "<fg=default;bg=default>\n</>").split '\n'
          nb_lines = lines.size > nb_lines ? cell_value.count('\n') : nb_lines

          rows[line].as(Row)[column] = Table::Cell.new lines.first, colspan: cell.colspan, style: cell.style
        end

        fill = Hash(Int32, Hash(Int32, Table::Cell)).new
        nb_lines.times do |l|
          fill[line + 1 + l] = Hash(Int32, Table::Cell).new
        end

        unmerged_rows = fill.merge! unmerged_rows

        unmerged_rows.each do |unmerged_row_key, unmerged_row|
          value = lines[unmerged_row_key - line]? || ""
          (unmerged_rows[unmerged_row_key] ||= Hash(Int32, Table::Cell).new)[column] = Table::Cell.new value, colspan: cell.colspan, style: cell.style

          if nb_lines == unmerged_row_key - line
            break
          end
        end
      end
    end

    unmerged_rows.each do |unmerged_row_key, unmerged_row|
      if (ur = rows[unmerged_row_key]?) && ur.is_a?(Enumerable) && ((self.get_number_of_columns(ur) + self.get_number_of_columns(unmerged_rows[unmerged_row_key])) <= @number_of_columns.not_nil!)
        unmerged_row.each do |cell_key, c|
          rows[unmerged_row_key].as(Row).insert cell_key, c
        end
      else
        row = self.copy_row rows, unmerged_row_key - 1
        unmerged_row.each do |column, c|
          row[column] = unmerged_row[column]
        end

        rows.insert unmerged_row_key, Row.new row.values
      end
    end
  end

  # Fills cells for a colspan > 1
  private def fill_cells(row : Row) : Array(Row::Type)
    new_row = [] of String | Table::Cell

    row.each_with_index do |cell, column|
      new_row << cell

      if cell.is_a?(Table::Cell) && cell.colspan > 1
        ((column + 1)...(column + cell.colspan)).each do
          new_row << ""
        end
      end
    end

    new_row.empty? ? row.to_a : new_row
  end #

  # OPTIMIZE: See about making Row an Enumerable({Int32, Row::Type}) to allow both Row and Hash contexts
  private def fill_cells(row : Hash(Int32, Row::Type)) : Array(Row::Type)
    new_row = [] of String | Table::Cell

    row.each do |column, cell|
      new_row << cell

      if cell.is_a?(Table::Cell) && cell.colspan > 1
        ((column + 1)...(column + cell.colspan)).each do
          new_row << ""
        end
      end
    end

    new_row
  end

  private def copy_row(rows : Array(InternalRowType), line : Int32) : Hash(Int32, String | Table::Cell)
    new_row = Hash(Int32, String | Table::Cell).new
    rows[line].as(Row).each_with_index do |cell, cell_key|
      new_row[cell_key] = ""

      if cell.is_a? Table::Cell
        new_row[cell_key] = Table::Cell.new("", colspan: cell.colspan)
      end
    end

    new_row
  end

  private def calculate_number_of_columns(rows : Enumerable) : Nil
    columns = [0]

    rows.each do |row|
      next if row.is_a? ACON::Helper::Table::Separator

      columns << self.get_number_of_columns row
    end

    @number_of_columns = columns.max
  end

  private def calculate_columns_width(groups : Rows) : Nil
    @number_of_columns.not_nil!.times do |column|
      lengths = [] of Int32

      groups.each do |group|
        group.each do |row|
          # Avoid mutating the actual row, as the logic below is just used to calculate widths
          row = row.dup

          next if row.is_a? Table::Separator

          row.each_with_index do |cell, idx|
            if cell.is_a? Table::Cell
              text_content = Helper.remove_decoration @output.formatter, cell.to_s
              text_length = Helper.width text_content

              if text_length > 0
                # Split content into an array of n chars each
                content_columns = text_content.split(/(#{"." * (text_length / cell.colspan).ceil.to_i})/, remove_empty: true)

                content_columns.each_with_index do |content, position|
                  row[idx + position] = content
                end
              end
            end
          end

          lengths << self.get_cell_width row, column
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

  private def get_column_separator_width : Int32
    Helper.width sprintf @style.border_format, @style.border_chars[3]
  end

  private def get_number_of_columns(row : Enumerable) : Int32
    columns = row.size

    row.each do |column|
      columns += column.is_a?(ACON::Helper::Table::Cell) ? column.colspan - 1 : 0
    end

    columns
  end

  private def calculate_row_count : Int32
    number_of_rows = self.combined_rows(Table::Separator.new).size

    unless @headers.empty?
      number_of_rows += 1
    end

    unless @rows.empty?
      number_of_rows += 1
    end

    number_of_rows
  end

  private enum RowSeparator
    TOP
    TOP_BOTTOM
    MIDDLE
    BOTTOM
  end

  private def render_row_separator(type : RowSeparator = :middle, title : String? = nil, title_format : String? = nil) : Nil
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
      break "" if count.zero?

      io << left_char

      count.times do |column|
        io << horizontal * @effective_column_widths[column]
        io << ((column == (count - 1)) ? right_char : middle_char)
      end
    end

    if !title.nil? && title_format
      title_length = Helper.width Helper.remove_decoration((formatter = @output.formatter), (formatted_title = sprintf(title_format, title)))
      markup_length = Helper.width markup

      if title_length > (limit = markup_length - 4)
        title_length = limit
        format_length = Helper.width Helper.remove_decoration(formatter, sprintf(title_format, ""))
        formatted_title = sprintf title_format, "#{title[0, limit - format_length - 3]}..."
      end

      title_start = (markup_length - title_length) // 2
      markup = "#{markup[0, title_start]}#{formatted_title}#{markup[((title_start + title_length)..)]}"
    end

    return unless markup.presence

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
    cell = (row[column]? || "")
    cell_value = cell.to_s
    width = @effective_column_widths[column]

    if cell.is_a?(Table::Cell) && cell.colspan > 1
      # Add the width of the following columns (numbers of colspan)
      ((column + 1)..(column + cell.colspan - 1)).each do |next_column|
        width += self.get_column_separator_width + @effective_column_widths[next_column]
      end
    end

    style = self.get_column_style column
    padding_style = style

    if cell.is_a? Table::Separator
      return sprintf style.border_format, style.border_chars[2] * width
    end

    width += cell_value.size - Helper.remove_decoration(@output.formatter, cell_value).size
    content = sprintf style.cell_row_content_format, cell_value

    if cell.is_a?(Table::Cell) && (cell_style = cell.style)
      unless cell_value.matches? /^<(\w+|(\w+=[\w,]+;?)*)>.+<\/(\w+|(\w+=\w+;?)*)?>$/
        unless cell_format = cell_style.format
          tag = cell_style.tag
          cell_format = "<#{tag}>%s</>"
        end

        if content.includes? "</>"
          content = content.gsub "</>", ""
          width -= 3
        end

        if content.includes? "<fg=default;bg=default>"
          content = content.gsub "<fg=default;bg=default>", ""
          width -= "<fg=default;bg=default>".size
        end
      end

      padding_style = cell_style
    end

    sprintf cell_format, padding_style.pad(content, width, style.padding_char)
  end

  private def get_row_columns(row : Rows::Type) : Array(Int32)
    columns = (0...@number_of_columns).to_a

    row.each_with_index do |cell, cell_key|
      if cell.is_a? Table::Cell
        # Exclude grouped columns
        columns = columns - ((cell_key + 1)...(cell_key + cell.colspan)).to_a
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

  # Helper method that allows iterating over the cells of a row, skipping cell separators
  private def iterate_row(rows : Enumerable, line : Int32, & : String | ACON::Helper::Table::Cell, Int32 ->) : Nil
    columns = rows[line]

    return if columns.is_a? ACON::Helper::Table::Separator

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
    self.class.styles[style]? || raise ACON::Exceptions::InvalidArgument.new "The table style '#{style}' is not defined."
  end
end
