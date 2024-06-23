# Represents the overall style for a table.
# Including the characters that make up the row/column separators, crosses, cell formats, and default alignment.
#
# This class provides a fluent interface for configuring each part of the style.
class Athena::Console::Helper::Table::Style
  @horizontal_outside_border_char = "-"
  @horizontal_inside_border_char = "-"
  @vertical_outside_border_char = "|"
  @vertical_inside_border_char = "|"

  @crossing_char : String = "+"
  @crossing_top_right_char = "+"
  @crossing_top_middle_char = "+"
  @crossing_top_left_char = "+"
  @crossing_bottom_right_char = "+"
  @crossing_bottom_middle_char = "+"
  @crossing_bottom_left_char = "+"
  @crossing_middle_right_char = "+"
  @crossing_middle_left_char = "+"
  @crossing_top_left_bottom_char = "+"
  @crossing_top_middle_bottom_char = "+"
  @crossing_top_right_bottom_char = "+"

  protected getter padding_char : Char = ' '
  protected getter header_title_format : String = "<fg=black;bg=white;options=bold> %s </>"
  protected getter footer_title_format : String = "<fg=black;bg=white;options=bold> %s </>"
  protected getter cell_header_format : String = "<info>%s</info>"
  protected getter cell_row_format : String = "%s"
  protected getter cell_row_content_format : String = " %s "
  protected getter border_format : String = "%s"
  protected getter align : ACON::Helper::Table::Alignment = :left

  def_clone

  # Sets the default cell alignment for the table.
  #
  # See `ACON::Helper::Table::Alignment`.
  def align(@align : ACON::Helper::Table::Alignment) : self
    self
  end

  # Sets the `sprintf` format string for the border, defaulting to `"%s"`.
  #
  # For example, if set to `"~%s~"` with the cell's content being `text`:
  #
  # ```text
  # ~+------+~
  # ~|~ text ~|~
  # ~+------+~
  # ```
  #
  # WARNING: Customizing this format can mess with the formatting of the whole table.
  def border_format(format : String) : self
    @border_format = format

    self
  end

  # Sets the the character that is added to the cell to ensure its content has the correct `ACON::Helper::Table::Alignment`, defaulting to `' '`.
  #
  # For example, if the padding character was `'_'` with a left alignment:
  #
  # ```text
  # +-----+
  # | 7 __|
  # +-----+
  # ```
  def padding_char(char : Char) : self
    raise ACON::Exception::Logic.new "The padding char cannot be empty" if char.empty?

    @padding_char = char

    self
  end

  # Sets the `sprintf` format string used for [header titles][Athena::Console::Helper::Table--headerfooter-titles], defaulting to `"<fg=black;bg=white;options=bold> %s </>"`.
  def header_title_format(format : String) : self
    @header_title_format = format.to_s

    self
  end

  # Sets the `sprintf` format string used for [footer titles][Athena::Console::Helper::Table--headerfooter-titles], defaulting to `"<fg=black;bg=white;options=bold> %s </>"`.
  def footer_title_format(format : String) : self
    @footer_title_format = format.to_s

    self
  end

  # Sets the `sprintf` format string used for table headings, defaulting to `"<info>%s</info>"`.
  def cell_header_format(format : String) : self
    @cell_header_format = format.to_s

    self
  end

  # Sets the `sprintf` format string used for cell contents, defaulting to `"%s"`.
  #
  # For example, if set to `"~%s~"` with the cell's content being `text`:
  #
  # ```text
  # +------+
  # |~ text ~|
  # +------+
  # ```
  #
  # WARNING: Customizing this format can mess with the formatting of the whole table.
  def cell_row_format(format : String) : self
    @cell_row_format = format.to_s

    self
  end

  # Sets the `sprintf` format string used for cell contents, defaulting to `" %s "`.
  #
  # For example, if set to `" =%s= "` with the cell's content being `text`:
  #
  # ```text
  # +--------+
  # | =text= |
  # +--------+
  # ```
  def cell_row_content_format(format : String) : self
    @cell_row_content_format = format.to_s

    self
  end

  protected def pad(string : String, width : Int32, padding_char) : String
    case @align
    in .left?   then string.ljust width, padding_char
    in .right?  then string.rjust width, padding_char
    in .center? then string.center width, padding_char
    end
  end

  # Sets the horizontal border chars, defaulting to `"-"`.
  #
  # *inside* defaults to *outside* if not provided.
  #
  # For example:
  #
  # ```
  # ╔═══════════════╤══════════════════════════╤══════════════════╗
  # 1 ISBN          2 Title                    │ Author           ║
  # ╠═══════════════╪══════════════════════════╪══════════════════╣
  # ║ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  ║
  # ║ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  ║
  # ║ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien ║
  # ║ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  ║
  # ╚═══════════════╧══════════════════════════╧══════════════════╝
  # ```
  #
  # Legend:
  #
  # * #1 *outside*
  # * #2 *inside*
  def horizontal_border_chars(outside : String | Char, inside : String | Char | Nil = nil) : self
    @horizontal_outside_border_char = outside.to_s
    @horizontal_inside_border_char = inside.try &.to_s || outside.to_s

    self
  end

  # Sets the vertical border chars, defaulting to `"|"`.
  #
  # *inside* defaults to *outside* if not provided.
  #
  # For example:
  #
  # ```
  # ╔═══════════════╤══════════════════════════╤══════════════════╗
  # ║ ISBN          │ Title                    │ Author           ║
  # ╠═══════1═══════╪══════════════════════════╪══════════════════╣
  # ║ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  ║
  # ║ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  ║
  # ╟───────2───────┼──────────────────────────┼──────────────────╢
  # ║ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien ║
  # ║ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  ║
  # ╚═══════════════╧══════════════════════════╧══════════════════╝
  # ```
  #
  # Legend:
  #
  # * #1 *outside*
  # * #2 *inside*
  def vertical_border_chars(outside : String | Char, inside : String | Char | Nil = nil) : self
    @vertical_outside_border_char = outside.to_s
    @vertical_inside_border_char = inside.try &.to_s || outside.to_s

    self
  end

  protected def border_chars : Tuple(String, String, String, String)
    {
      @horizontal_outside_border_char,
      @vertical_outside_border_char,
      @horizontal_inside_border_char,
      @vertical_inside_border_char,
    }
  end

  # Sets the crossing characters individually, defaulting to `"+"`.
  # See `#default_crossing_char(char)` to default them all to a single character.
  #
  # ```
  # 1═══════════════2══════════════════════════2══════════════════3
  # ║ ISBN          │ Title                    │ Author           ║
  # 8═══════════════0══════════════════════════0══════════════════4
  # ║ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  ║
  # ║ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  ║
  # 8───────────────0──────────────────────────0──────────────────4
  # ║ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien ║
  # ║ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  ║
  # 7═══════════════6══════════════════════════6══════════════════5
  # ```
  #
  # Legend:
  #
  # * #0 *cross*
  # * #1 *top_left*
  # * #2 *top_middle*
  # * #3 *top_right*
  # * #4 *middle_right*
  # * #5 *bottom_right*
  # * #6 *bottom_middle*
  # * #7 *bottom_left*
  # * #8 *middle_left*
  #
  # * #8 *top_left_bottom* - defaults to *middle_left* if `nil`
  # * #0 *top_middle_bottom* - defaults to *cross* if `nil`
  # * #4 *top_right_bottom* - defaults to *middle_right* if `nil`
  def crossing_chars(
    cross : String | Char,
    top_left : String | Char,
    top_middle : String | Char,
    top_right : String | Char,
    middle_right : String | Char,
    bottom_right : String | Char,
    bottom_middle : String | Char,
    bottom_left : String | Char,
    middle_left : String | Char,
    top_left_bottom : String | Char | Nil = nil,
    top_middle_bottom : String | Char | Nil = nil,
    top_right_bottom : String | Char | Nil = nil
  ) : self
    @crossing_char = cross.to_s
    @crossing_top_left_char = top_left.to_s
    @crossing_top_middle_char = top_middle.to_s
    @crossing_top_right_char = top_right.to_s
    @crossing_middle_right_char = middle_right.to_s
    @crossing_bottom_right_char = bottom_right.to_s
    @crossing_bottom_middle_char = bottom_middle.to_s
    @crossing_bottom_left_char = bottom_left.to_s
    @crossing_middle_left_char = middle_left.to_s

    @crossing_top_left_bottom_char = top_left_bottom.try &.to_s || middle_left.to_s
    @crossing_top_middle_bottom_char = top_middle_bottom.try &.to_s || cross.to_s
    @crossing_top_right_bottom_char = top_right_bottom.try &.to_s || middle_right.to_s

    self
  end

  # Sets the default character used for each cross type.
  #
  # See `#crossing_chars`.
  def default_crossing_char(char : String | Char) : self
    self
      .crossing_chars(
        char,
        char,
        char,
        char,
        char,
        char,
        char,
        char,
        char,
      )

    self
  end

  protected def crossing_chars : Tuple(String, String, String, String, String, String, String, String, String, String, String, String)
    {
      @crossing_char,
      @crossing_top_left_char,
      @crossing_top_middle_char,
      @crossing_top_right_char,
      @crossing_middle_right_char,
      @crossing_bottom_right_char,
      @crossing_bottom_middle_char,
      @crossing_bottom_left_char,
      @crossing_middle_left_char,
      @crossing_top_left_bottom_char,
      @crossing_top_middle_bottom_char,
      @crossing_top_right_bottom_char,
    }
  end
end
