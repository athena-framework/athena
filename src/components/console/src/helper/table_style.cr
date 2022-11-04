class Athena::Console::Helper::Table::Style
  enum Align
    LEFT
    RIGHT
    CENTER
  end

  # Returns the character used for cell padding.
  getter padding_char : Char = ' '

  @horizontal_outside_border_char = "-"
  @horizontal_inside_border_char = "-"
  @vertical_outside_border_char = "|"
  @vertical_inside_border_char = "|"

  # Returns the character used for crosses.
  getter crossing_char : String = "+"

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

  property header_title_format : String = "<fg=black;bg=white;options=bold> %s </>"
  property footer_title_format : String = "<fg=black;bg=white;options=bold> %s </>"

  property cell_header_format : String = "<info>%s</info>"
  property cell_row_format : String = "%s"
  property cell_row_content_format : String = " %s "

  property border_format : String = "%s"

  property align : Align = :right

  def padding_char=(char : Char) : self
    raise ArgumentError.new "The padding char cannot be empty" if char.empty?

    @padding_char = char

    self
  end

  protected def pad(string : String, width : Int32, padding_char) : String
    case @align
    in .left?   then string.rjust width, padding_char
    in .right?  then string.ljust width, padding_char
    in .center? then string.center width, padding_char
    end
  end

  # Sets the horizontal border chars, for example:
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
  def horizontal_border_chars(outside : String, inside : String? = nil) : self
    self.horizontal_outside_border_char outside
    self.horizontal_inside_border_char inside || outside

    self
  end

  # Sets the vertical border chars, for example:
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
  def vertical_border_chars(outside : String, inside : String? = nil) : self
    self.vertical_outside_border_char outside
    self.vertical_outside_border_char inside || outside

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

  # Sets the crossing characters.
  #
  # ```
  # 1═══════════════2══════════════════════════2══════════════════3
  # ║ ISBN          │ Title                    │ Author           ║
  # 8'══════════════0'═════════════════════════0'═════════════════4'
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
    cross : String,
    top_left : String,
    top_middle : String,
    top_right : String,
    middle_right : String,
    bottom_right : String,
    bottom_middle : String,
    bottom_left : String,
    middle_left : String,
    top_left_bottom : String? = nil,
    top_middle_bottom : String? = nil,
    top_right_bottom : String? = nil
  ) : self
    @crossing_char = cross
    @crossing_top_left_char = top_left
    @crossing_top_middle_char = top_middle
    @crossing_top_right_char = top_right
    @crossing_middle_right_char = middle_right
    @crossing_bottom_right_char = bottom_right
    @crossing_bottom_middle_char = bottom_middle
    @crossing_bottom_left_char = bottom_left
    @crossing_middle_left_char = middle_left

    @crossing_top_left_bottom_char = top_left_bottom || middle_left
    @crossing_top_middle_bottom_char = top_middle_bottom || cross
    @crossing_top_right_bottom_char = top_right_bottom || middle_right

    self
  end

  # Sets the default character used for each cross.
  #
  # See `#crossing_chars`.
  def default_crossing_char(char : String) : self
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
