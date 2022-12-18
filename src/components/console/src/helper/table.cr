# The Table helper can be used to display tabular data rendered to any `ACON::Output::Interface`.
#
# ```text
# +---------------+--------------------------+------------------+
# | ISBN          | Title                    | Author           |
# +---------------+--------------------------+------------------+
# | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
# | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
# | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
# | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
# +---------------+--------------------------+------------------+
# ```
#
# # Usage
#
# Most commonly, a table will consist of a header row followed by one or more data rows:
# ```
# @[ACONA::AsCommand("table")]
# class TableCommand < ACON::Command
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     ACON::Helper::Table.new(output)
#       .headers("ISBN", "Title", "Author")
#       .rows([
#         ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
#         ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
#         ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
#         ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
#       ])
#       .render
#
#     ACON::Command::Status::SUCCESS
#   end
# end
# ```
#
# ## Separating Rows
#
# Row separators can be added anywhere in the output by passing an `ACON::Helper::Table::Separator` as a row.
#
# ```
# table
#   .rows([
#     ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
#     ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
#     ACON::Helper::Table::Separator.new,
#     ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
#     ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
#   ])
# ```
#
# ```text
# +---------------+--------------------------+------------------+
# | ISBN          | Title                    | Author           |
# +---------------+--------------------------+------------------+
# | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
# | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
# +---------------+--------------------------+------------------+
# | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
# | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
# +---------------+--------------------------+------------------+
# ```
#
# ## Header/Footer Titles
#
# Header and/or footer titles can optionally be added via the `#header_title` and/or `#footer_title` methods.
#
# ```
# table
#   .header_title("Books")
#   .footer_title("Page 1/2")
# ```
#
# ```text
# +---------------+----------- Books --------+------------------+
# | ISBN          | Title                    | Author           |
# +---------------+--------------------------+------------------+
# | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
# | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
# +---------------+--------------------------+------------------+
# | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
# | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
# +---------------+--------- Page 1/2 -------+------------------+
# ```
#
# ## Column Sizing
#
# By default, the width of each column is calculated automatically based on their contents.
# The `#column_widths` method can be used to set the column widths explicitly.
#
# ```
# table
#   .column_widths(10, 0, 30)
#   .render
# ```
#
# In this example, the first column's width will be `10`, the last column's width will be `30`, and the second column's width will be calculated automatically since it is zero.
# If you only want to set the width of a specific column, the `#column_width` method can be used.
#
# ```
# table
#   .column_width(0, 10)
#   .column_width(2, 30)
#   .render
# ```
#
# The resulting table would be:
#
# ```text
# +---------------+------------------ Books -+--------------------------------+
# | ISBN          | Title                    | Author                         |
# +---------------+--------------------------+--------------------------------+
# | 99921-58-10-7 | Divine Comedy            | Dante Alighieri                |
# | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens                |
# +---------------+--------------------------+--------------------------------+
# | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien               |
# | 80-902734-1-6 | And Then There Were None | Agatha Christie                |
# +---------------+--------------------------+--------------------------------+
# ```
#
# Notice that the width of the first column is greater than 10 characters wide.
# This is because column widths are always considered as the minimum width.
# If the content doesn't fit, it will be automatically increased to the longest content length.
#
# ### Max Width
#
# If you would rather wrap the contents in multiple rows, the `#column_max_width` method can be used.
#
# ```
# table
#   .column_max_width(0, 5)
#   .column_max_width(1, 10)
#   .render
# ```
#
# This would cause the table to now be:
#
# ```text
# +-------+------------+-- Books -----------------------+
# | ISBN  | Title      | Author                         |
# +-------+------------+--------------------------------+
# | 99921 | Divine Com | Dante Alighieri                |
# | -58-1 | edy        |                                |
# | 0-7   |            |                                |
# |                (the rest of the rows...)            |
# +-------+------------+--------------------------------+
# ```
#
# ## Orientation
#
# By default, the table contents are displayed as a normal table with the data being in rows, the first being the header row(s).
# The table can also be rendered vertically or horizontally via the `#vertical` and `#horizontal` methods respectively.
#
# For example, the same contents rendered vertically would be:
#
# ```text
# +----------------------------------+
# |   ISBN: 99921-58-10-7            |
# |  Title: Divine Comedy            |
# | Author: Dante Alighieri          |
# |----------------------------------|
# |   ISBN: 9971-5-0210-0            |
# |  Title: A Tale of Two Cities     |
# | Author: Charles Dickens          |
# |----------------------------------|
# |   ISBN: 960-425-059-0            |
# |  Title: The Lord of the Rings    |
# | Author: J. R. R. Tolkien         |
# |----------------------------------|
# |   ISBN: 80-902734-1-6            |
# |  Title: And Then There Were None |
# | Author: Agatha Christie          |
# +----------------------------------+
# ```
#
# While horizontally, it would be:
#
# ```text
# +--------+-----------------+----------------------+-----------------------+--------------------------+
# | ISBN   | 99921-58-10-7   | 9971-5-0210-0        | 960-425-059-0         | 80-902734-1-6            |
# | Title  | Divine Comedy   | A Tale of Two Cities | The Lord of the Rings | And Then There Were None |
# | Author | Dante Alighieri | Charles Dickens      | J. R. R. Tolkien      | Agatha Christie          |
# +--------+-----------------+----------------------+-----------------------+--------------------------+
# ```
#
# ## Styles
#
# Up until now, all the tables have been rendered using the `default` style.
# The table helper comes with a few additional built in styles, including:
#
# * borderless
# * compact
# * box
# * double-box
#
# The desired can be set via the `#style` method.
#
# ```
# table
#   .style("default") # Same as not calling the method
#   .render
# ```
#
# ### borderless
#
# ```text
# =============== ========================== ==================
#  ISBN            Title                      Author
# =============== ========================== ==================
#  99921-58-10-7   Divine Comedy              Dante Alighieri
#  9971-5-0210-0   A Tale of Two Cities       Charles Dickens
# =============== ========================== ==================
#  960-425-059-0   The Lord of the Rings      J. R. R. Tolkien
#  80-902734-1-6   And Then There Were None   Agatha Christie
# =============== ========================== ==================
# ```
#
# ### compact
#
# ```text
# ISBN          Title                    Author
# 99921-58-10-7 Divine Comedy            Dante Alighieri
# 9971-5-0210-0 A Tale of Two Cities     Charles Dickens
# 960-425-059-0 The Lord of the Rings    J. R. R. Tolkien
# 80-902734-1-6 And Then There Were None Agatha Christie
# ```
#
# ### box
#
# ```text
# ┌───────────────┬──────────────────────────┬──────────────────┐
# │ ISBN          │ Title                    │ Author           │
# ├───────────────┼──────────────────────────┼──────────────────┤
# │ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  │
# │ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  │
# ├───────────────┼──────────────────────────┼──────────────────┤
# │ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien │
# │ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  │
# └───────────────┴──────────────────────────┴──────────────────┘
# ```
#
# ### double-box
#
# ```text
# ╔═══════════════╤══════════════════════════╤══════════════════╗
# ║ ISBN          │ Title                    │ Author           ║
# ╠═══════════════╪══════════════════════════╪══════════════════╣
# ║ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  ║
# ║ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  ║
# ╟───────────────┼──────────────────────────┼──────────────────╢
# ║ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien ║
# ║ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  ║
# ╚═══════════════╧══════════════════════════╧══════════════════╝
# ```
#
# ## Custom Styles
#
# If you would rather something more personal, custom styles can also be defined by providing `#style` with an `ACON::Helper::Table::Style` instance.
#
# ```
# table_style = ACON::Helper::Table::Style.new
#   .horizontal_border_chars("<fg=magenta>|</>")
#   .vertical_border_chars("<info>-</>")
#   .default_crossing_char(' ')
#
# table
#   .style(table_style)
#   .render
# ```
#
# Notice you can use the same style tags as you can with `ACON::Formatter::OutputStyleInterface`s.
# This is used by default to give some color to headers when allowed.
#
# TIP: Custom styles can also be registered globally:
# ```
# ACON::Helper::Table.set_style_definition "colorful", table_style
#
# # ...
#
# table.style("colorful")
# ```
# This method can also be used to override the built-in styles.
#
# See `ACON::Helper::Table::Style` for more information.
#
# ## Table Cells
#
# The `ACON::Helper::Table::Cell` type can be used to style a specific cell.
# Such as customizing the fore/background color, the alignment of the text, or the overall format of the cell.
#
# See the related type for more information/examples.
#
# ### Spanning Multiple Columns and Rows
#
# The `ACON::Helper::Table::Cell` type can also be used to add *colspan* and/or *rowspan* to a cell;
# which would make it span more than one column/row.
#
# ```
# ACON::Helper::Table.new(output)
#   .headers("ISBN", "Title", "Author")
#   .rows([
#     ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
#     ACON::Helper::Table::Separator.new,
#     [ACON::Helper::Table::Cell.new("This value spans 3 columns.", colspan: 3)],
#   ])
#   .render
# ```
#
# This would result in:
#
# ```text
# +---------------+---------------+-----------------+
# | ISBN          | Title         | Author          |
# +---------------+---------------+-----------------+
# | 99921-58-10-7 | Divine Comedy | Dante Alighieri |
# +---------------+---------------+-----------------+
# | This value spans 3 columns.                     |
# +---------------+---------------+-----------------+
# ```
#
# TIP: This table cells with colspan and `center` alignment can be used to create header cells that span the entire table width:
# ```
# table
#   .headers([
#     [ACON::Helper::Table::Cell.new(
#       "Main table title",
#       colspan: 3,
#       style: ACON::Helper::Table::CellStyle.new(
#         align: :center
#       )
#     )],
#     %w(ISBN Title Author),
#   ])
# ```
# Would generate:
# ```text
# +--------+--------+--------+
# |     Main table title     |
# +--------+--------+--------+
# | ISBN   | Title  | Author |
# +--------+--------+--------+
# ```
#
# In a similar way, *rowspan* can be used to have a column span multiple rows.
# This is especially helpful for columns with line breaks.
#
# ```
# ACON::Helper::Table.new(output)
#   .headers("ISBN", "Title", "Author")
#   .rows([
#     [
#       "978-0521567817",
#       "De Monarchia",
#       ACON::Helper::Table::Cell.new("Dante Alighieri\nspans multiple rows", rowspan: 2),
#     ],
#     ["978-0804169127", "Divine Comedy"],
#   ])
#   .render
# ```
#
# This would result in:
#
# ```text
# +----------------+---------------+---------------------+
# | ISBN           | Title         | Author              |
# +----------------+---------------+---------------------+
# | 978-0521567817 | De Monarchia  | Dante Alighieri     |
# | 978-0804169127 | Divine Comedy | spans multiple rows |
# +----------------+---------------+---------------------+
# ```
#
# *colspan* and *rowspan* may also be used together to create any layout you can think of.
#
# ## Modifying Rendered Tables
#
# The `#render` method requires providing the entire table's content in order to fully render the table.
# In some cases, that may not be possible if the data is generated dynamically.
# In such cases, the `#append_row` method can be used which functions similarly to `#add_row`, but will append the rows to an already rendered table.
#
# INFO: This feature is only available when the table is rendered in an `ACON::Output::Section`.
#
# ```
# @[ACONA::AsCommand("table")]
# class TableCommand < ACON::Command
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     section = output.section
#     table = ACON::Helper::Table.new(section)
#       .add_row("Foo")
#
#     table.render
#
#     table.append_row "Bar"
#
#     ACON::Command::Status::SUCCESS
#   end
# end
# ```
#
# This ultimately results in:
#
# ```text
# +-----+
# | Foo |
# | Bar |
# +-----+
# ```
class Athena::Console::Helper::Table
  # Represents how the text within a cell should be aligned.
  enum Alignment
    # Aligns the text to the left of the cell.
    #
    # ```text
    # +-----------------+
    # | Text            |
    # +-----------------+
    # ```
    LEFT

    # Aligns the text to the right of the cell.
    #
    # ```text
    # +-----------------+
    # |            Text |
    # +-----------------+
    # ```
    RIGHT

    # Centers the text within the cell.
    #
    # ```text
    # +-----------------+
    # |      Text       |
    # +-----------------+
    # ```
    CENTER
  end

  private enum Orientation
    DEFAULT
    HORIZONTAL
    VERTICAL
  end

  # Represents a cell that can span more than one column/row and/or have a unique style.
  # The cell may also have a value, which represents the value to display in the cell.
  #
  # For example:
  #
  # ```
  # table
  #   .rows([
  #     [
  #       "Foo",
  #       ACON::Helper::Table::Cell.new(
  #         "Bar",
  #         style: ACON::Helper::Table::CellStyle.new(
  #           align: :center,
  #           foreground: "red",
  #           background: "green"
  #         )
  #       ),
  #     ],
  #   ])
  # ```
  #
  # See the [table docs][Athena::Console::Helper::Table--table-cells] and `ACON::Helper::Table::CellStyle` for more information.
  class Cell
    # Returns how many rows this cell should span.
    getter rowspan : Int32

    # Returns how many columns this cell should span.
    getter colspan : Int32

    # Returns the style representing how this cell should be styled.
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

  # Represents a line that separates one or more rows.
  #
  # See the [separating rows][Athena::Console::Helper::Table--separating-rows] section for more information.
  class Separator < Table::Cell
    def initialize(
      rowspan : Int32 = 1,
      colspan : Int32 = 1,
      style : Table::CellStyle? = nil
    )
      super "", rowspan, colspan, style
    end
  end

  # The possible types that are accepted as cell values.
  # They are all eventually turned into strings.
  alias CellType = String | Number::Primitive | Bool | Athena::Console::Helper::Table::Cell | Nil

  # The possible types that represent a row.
  alias RowType = Enumerable(CellType) | Athena::Console::Helper::Table::Separator

  private struct Row
    alias Type = String | Table::Cell | Nil

    include Indexable::Mutable(Type)

    delegate :insert, :<<, :[], to: @columns

    @columns : Array(Type)

    def self.new(columns : Enumerable(CellType))
      new(columns.map do |c|
        case c
        when Athena::Console::Helper::Table::Cell, Nil then c
        else                                                c.to_s
        end
      end)
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

  # Registers the provided *style* with the provided *name*.
  #
  # See [custom styles][Athena::Console::Helper::Table--custom-styles].
  def self.set_style_definition(name : String, style : ACON::Helper::Table::Style) : Nil
    self.styles[name] = style
  end

  # Returns the `ACON::Helper::Table::Style` style with the provided *name*,
  # raising an `ACON::Exceptions::InvalidArgument` if no style with that name is defined.
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
  @column_styles = Hash(Int32, ACON::Helper::Table::Style).new
  @column_widths = Hash(Int32, Int32).new
  @column_max_widths = Hash(Int32, Int32).new
  @rendered = false
  @orientation : Orientation = :default

  # Returns the `ACON::Helper::Table::Style` used by this table.
  getter style : ACON::Helper::Table::Style

  @output : ACON::Output::Interface

  def initialize(@output : ACON::Output::Interface)
    @style = ACON::Helper::Table::Style.new
  end

  # Sets the table [header title][Athena::Console::Helper::Table--headerfooter-titles].
  def header_title(@header_title : String?) : self
    self
  end

  # Sets the table [footer title][Athena::Console::Helper::Table--headerfooter-titles].
  def footer_title(@footer_title : String?) : self
    self
  end

  # Sets the style of this table.
  # *style* may either be an explicit `ACON::Helper::Table::Style`,
  # or the name of the style to use if it is built-in, or was registered via `.set_style_definition`.
  #
  # See [styles][Athena::Console::Helper::Table--styles] and [custom styles][Athena::Console::Helper::Table--custom-styles].
  def style(style : String | ACON::Helper::Table::Style) : self
    @style = self.resolve_style style

    self
  end

  # Sets the style of the column at the provided *index*.
  # *style* may either be an explicit `ACON::Helper::Table::Style`,
  # or the name of the style to use if it is built-in, or was registered via `.set_style_definition`.
  def column_style(index : Int32, style : ACON::Helper::Table::Style | String) : self
    @column_styles[index] = self.resolve_style style

    self
  end

  # Returns the `ACON::Helper::Table::Style` the column at the provided *index* is using, falling back on `#style`.
  def column_style(index : Int32) : ACON::Helper::Table::Style
    @column_styles[index]? || self.style
  end

  # Sets the minimum *width* for the column at the provided *index*.
  #
  # See [column sizing][Athena::Console::Helper::Table--column-sizing].
  def column_width(index : Int32, width : Int32) : self
    @column_widths[index] = width

    self
  end

  # Sets the minimum column widths to the provided *widths*.
  #
  # See [column sizing][Athena::Console::Helper::Table--column-sizing].
  def column_widths(widths : Enumerable(Int32)) : self
    @column_widths.clear

    widths.each_with_index do |w, idx|
      self.column_width idx, w
    end

    self
  end

  # :ditto:
  def column_widths(*widths : Int32) : self
    self.column_widths widths
  end

  # Sets the maximum *width* for the column at the provided *index*.
  #
  # See [column sizing][Athena::Console::Helper::Table--column-sizing].
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
  #
  # ```
  # table
  #   .rows(%w(Foo Bar Baz))
  #   .render
  # ```
  def rows(rows : RowType) : self
    self.rows({rows})
  end

  # Overrides the rows of this table to those provided in *rows*.
  #
  # ```
  # table
  #   .rows([
  #     %w(One Two Three),
  #     %w(Foo Bar Baz),
  #   ])
  #   .render
  # ```
  def rows(rows : Enumerable(RowType)) : self
    @rows.clear

    self.add_rows rows
  end

  # Similar to `#rows(rows : Enumerable(RowType))`, but appends the provided *rows* to this table.
  #
  # ```
  # # Existing rows are not removed.
  # table
  #   .add_rows([
  #     %w(One Two Three),
  #     %w(Foo Bar Baz),
  #   ])
  #   .render
  # ```
  def add_rows(rows : Enumerable(RowType)) : self
    rows.each do |r|
      self.add_row r
    end

    self
  end

  # Adds a single new *row* to this table.
  #
  # ```
  # # Existing rows are not removed.
  # table
  #   .add_row(%w(One Two Three))
  #   .add_row(%w(Foo Bar Baz))
  #   .render
  # ```
  def add_row(row : RowType) : self
    @rows << case row
    when Table::Separator then row
    else
      Row.new row
    end

    self
  end

  # Adds the provided *columns* as a single row to this table.
  #
  # ```
  # # Existing rows are not removed.
  # table
  #   .add_row("One", "Two", "Three")
  #   .add_row("Foo", "Bar", "Baz")
  #   .render
  # ```
  def add_row(*columns : CellType) : self
    self.add_row columns

    self
  end

  # Appends *row* to an already rendered table.
  #
  # See [modifying rendered tables][Athena::Console::Helper::Table--modifying-rendered-tables]
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

  # Appends the provided *columns* as a single row to an already rendered table.
  #
  # See [modifying rendered tables][Athena::Console::Helper::Table--modifying-rendered-tables]
  def append_row(*columns : CellType) : self
    self.append_row([*columns])
  end

  # Manually sets the provided *row* to the provided *index*.
  #
  # ```
  # # Existing rows are not removed.
  # table
  #   .add_row(%w(One Two Three))
  #   .row(0, %w(Foo Bar Baz)) # Overrides row 0 to this row
  #   .render
  # ```
  def row(index : Int32, row : RowType) : self
    @rows[index] = Row.new row

    self
  end

  # Changes this table's [orientation][Athena::Console::Helper::Table--orientation] to horizontal.
  def horizontal : self
    @orientation = :horizontal

    self
  end

  # Changes this table's [orientation][Athena::Console::Helper::Table--orientation] to vertical.
  def vertical : self
    @orientation = :vertical

    self
  end

  private alias InternalRowType = Row | ACON::Helper::Table::Separator

  # Renders this table to the `ACON::Output::Interface` it was instantiated with.
  #
  # ameba:disable Metrics/CyclomaticComplexity
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

  # ameba:disable Metrics/CyclomaticComplexity
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

  private def cleanup : Nil
    @effective_column_widths.clear
    @number_of_columns = nil
  end

  # ameba:disable Metrics/CyclomaticComplexity
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

    rows.each_with_index do |row, rk|
      row_group = [row.is_a?(Table::Separator) ? row : self.fill_cells(row)] of Rows::Type

      if ur = unmerged_rows[rk]?
        ur.each_value do |r|
          row_group << (r.is_a?(Table::Separator) ? r : self.fill_cells(r))
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

        unmerged_rows.each_key do |unmerged_row_key|
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
        unmerged_row.each_key do |column|
          row[column] = unmerged_row[column]
        end

        rows.insert unmerged_row_key, Row.new row.values
      end
    end
  end

  # Fills cells for a colspan > 1
  private def fill_cells(row : Row) : Array(Row::Type)
    new_row = [] of Row::Type

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
    new_row = [] of Row::Type

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

  # ameba:disable Metrics/CyclomaticComplexity
  private def render_row_separator(type : RowSeparator = :middle, title : String? = nil, title_format : String? = nil) : Nil
    return unless (count = @number_of_columns)

    borders = @style.border_chars
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
  private def iterate_row(rows : Enumerable, line : Int32, & : Row::Type, Int32 ->) : Nil
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
