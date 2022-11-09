require "../spec_helper"

struct TableSpec < ASPEC::TestCase
  @output : IO

  protected def get_table_contents(table_name : String) : String
    File.read File.join __DIR__, "..", "fixtures", "helper", "table", "#{table_name}.txt"
  end

  def initialize
    @output = IO::Memory.new
  end

  protected def tear_down : Nil
    @output.close
  end

  def test_rows_headers_overloads : Nil
    ACON::Helper::Table.new(output = self.io_output)
      .headers(["1", "2", 3])
      .headers([4, 5, 6])
      .headers(false, true, false)
      .add_row(["Foo", 123, 19.075])
      .add_row("Bar", 456, false)
      .add_rows([
        ["Baz"],
        ["Biz"],
      ])
      .row(0, %w(a b c))
      .render

    self.output_content(output).should eq <<-TABLE
    +-------+------+-------+
    | false | true | false |
    +-------+------+-------+
    | a     | b    | c     |
    | Bar   | 456  | false |
    | Baz   |      |       |
    | Biz   |      |       |
    +-------+------+-------+

    TABLE
  end

  @[DataProvider("render_provider")]
  def test_render(headers, rows, style : String, expected : String, decorated : Bool) : Nil
    table = ACON::Helper::Table.new output = self.io_output decorated
    table
      .headers(headers)
      .rows(rows)
      .style(style)
      .render

    self.output_content(output).should eq expected
  end

  def render_provider : Hash
    books = [
      ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
      ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
      ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
      ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
    ]

    {
      "Default style" => {
        [["ISBN", "Title", "Author"]],
        books,
        style = "default",
        self.get_table_contents(style),
        false,
      },
      "Compact style" => {
        [["ISBN", "Title", "Author"]],
        books,
        style = "compact",
        self.get_table_contents(style),
        false,
      },
      "Borderless style" => {
        [["ISBN", "Title", "Author"]],
        books,
        style = "borderless",
        self.get_table_contents(style),
        false,
      },
      "Box style" => {
        [["ISBN", "Title", "Author"]],
        books,
        style = "box",
        self.get_table_contents(style),
        false,
      },
      "Double box with separator" => {
        [["ISBN", "Title", "Author"]],
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
          ACON::Helper::Table::Separator.new,
          ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
          ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
        ],
        "double-box",
        self.get_table_contents("double_box_separator"),
        false,
      },
      "Default missing cell values" => {
        [["ISBN", "Title"]],
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          ["9971-5-0210-0"],
          ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
          ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
        ],
        "default",
        self.get_table_contents("default_missing_cell_values"),
        false,
      },
      "Default no headers" => {
        [[] of String],
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          ["9971-5-0210-0"],
          ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
          ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
        ],
        "default",
        self.get_table_contents("default_headerless"),
        false,
      },
      "Default multiline cells" => {
        [["ISBN", "Title", "Author"]],
        [
          ["99921-58-10-7", "Divine\nComedy", "Dante Alighieri"],
          ["9971-5-0210-2", "Harry Potter\nand the Chamber of Secrets", "Rowling\nJoanne K."],
          ["9971-5-0210-2", "Harry Potter\nand the Chamber of Secrets", "Rowling\nJoanne K."],
          ["960-425-059-0", "The Lord of the Rings", "J. R. R.\nTolkien"],
        ],
        "default",
        self.get_table_contents("default_multiline_cells"),
        false,
      },
      "Default no rows" => {
        [["ISBN", "Title"]],
        [] of String,
        "default",
        self.get_table_contents("default_no_rows"),
        false,
      },
      "Default no rows or headers" => {
        [[] of String],
        [] of String,
        "default",
        "",
        false,
      },
      "Default tags used for output formatting" => {
        [["ISBN", "Title", "Author"]],
        [
          ["<info>99921-58-10-7</info>", "<error>Divine Comedy</error>", "<fg=blue;bg=white>Dante Alighieri</fg=blue;bg=white>"],
          ["9971-5-0210-0", "A Tale of Two Cities", "<info>Charles Dickens</>"],
        ],
        "default",
        self.get_table_contents("default_cells_with_formatting_tags"),
        false,
      },
      "Default tags not used for output formatting" => {
        [["ISBN", "Title", "Author"]],
        [
          ["<strong>99921-58-10-700</strong>", "<f>Divine Com</f>", "Dante Alighieri"],
          ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
        ],
        "default",
        self.get_table_contents("default_cells_with_non_formatting_tags"),
        false,
      },
      "Default cells with colspan" => {
        [["ISBN", "Title", "Author"]],
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("Divine Comedy(Dante Alighieri)", colspan: 3),
          ],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("Arduino: A Quick-Start Guide", colspan: 2),
            "Mark Schmidt",
          ],
          ACON::Helper::Table::Separator.new,
          [
            "9971-5-0210-0",
            ACON::Helper::Table::Cell.new("A Tale of \nTwo Cities", colspan: 2),
          ],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("Cupiditate dicta atque porro, tempora exercitationem modi animi nulla nemo vel nihil!", colspan: 3),
          ],
        ],
        "default",
        self.get_table_contents("default_cells_with_colspan"),
        false,
      },
      "Default cell after colspan contains line break" => {
        [["Foo", "Bar", "Baz"]],
        [
          [
            ACON::Helper::Table::Cell.new("foo\nbar", colspan: 2),
            "baz\nqux",
          ],
        ],
        "default",
        self.get_table_contents("default_line_break_after_colspan_cell"),
        false,
      },
      "Default cell after colspan contains multiple line breaks" => {
        [["Foo", "Bar", "Baz"]],
        [
          [
            ACON::Helper::Table::Cell.new("foo\nbar", colspan: 2),
            "baz\nqux\nquux",
          ],
        ],
        "default",
        self.get_table_contents("default_line_breaks_after_colspan_cell"),
        false,
      },
      "Default cell with rowspan" => {
        [["ISBN", "Title", "Author"]],
        [
          [
            ACON::Helper::Table::Cell.new("9971-5-0210-0", rowspan: 3),
            ACON::Helper::Table::Cell.new("Divine Comedy", rowspan: 2),
            "Dante Alighieri",
          ],
          [] of String,
          ["The Lord of \nthe Rings", "J. R. \nR. Tolkien"],
          ACON::Helper::Table::Separator.new,
          ["80-902734-1-6", ACON::Helper::Table::Cell.new("And Then \nThere \nWere None", rowspan: 3), "Agatha Christie"],
          ["80-902734-1-7", "Test"],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan"),
        false,
      },
      "Default cell with rowspan and rowspan" => {
        [["ISBN", "Title", "Author"]],
        [
          [
            ACON::Helper::Table::Cell.new("9971-5-0210-0", rowspan: 2, colspan: 2),
            "Dante Alighieri",
          ],
          ["Charles Dickens"],
          ACON::Helper::Table::Separator.new,
          [
            "Dante Alighieri",
            ACON::Helper::Table::Cell.new("9971-5-0210-0", rowspan: 3, colspan: 2),
          ],
          ["J. R. R. Tolkien"],
          ["J. R. R"],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan"),
        false,
      },
      "Default cell with rowspan and colspan that contain new lines" => {
        [["ISBN", "Title", "Author"]],
        [
          [
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
            "Dante Alighieri",
          ],
          ["Charles Dickens"],
          ACON::Helper::Table::Separator.new,
          [
            "Dante Alighieri",
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
          ],
          ["Charles Dickens"],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
            ACON::Helper::Table::Cell.new("Dante \nAlighieri", rowspan: 2, colspan: 1),
          ],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_and_line_breaks"),
        false,
      },
      "Default cell with rowspan and colspan without table separators" => {
        [["ISBN", "Title", "Author"]],
        [
          [
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
            "Dante Alighieri",
          ],
          ["Charles Dickens"],
          [
            "Dante Alighieri",
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
          ],
          ["Charles Dickens"],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_no_separators"),
        false,
      },
      "Default cell with rowspan and colspan with separators inside a rowspan" => {
        [["ISBN", "Author"]],
        [
          [
            ACON::Helper::Table::Cell.new("9971-5-0210-0", rowspan: 3, colspan: 1),
            "Dante Alighieri",
          ],
          [ACON::Helper::Table::Separator.new],
          ["Charles Dickens"],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_separator_in_rowspan"),
        false,
      },
      "Default cell with multiple header lines" => {
        [
          [ACON::Helper::Table::Cell.new("Main title", colspan: 3)],
          ["ISBN", "Title", "Author"],
        ],
        [] of String,
        "default",
        self.get_table_contents("default_multiple_header_lines"),
        false,
      },
      "Default row with multiple cells" => {
        [[] of String],
        [
          [
            ACON::Helper::Table::Cell.new("1", colspan: 3),
            ACON::Helper::Table::Cell.new("2", colspan: 2),
            ACON::Helper::Table::Cell.new("3", colspan: 2),
            ACON::Helper::Table::Cell.new("4", colspan: 2),
          ],
        ],
        "default",
        self.get_table_contents("default_row_with_multiple_cells"),
        false,
      },
      "Default colspan and table cells with comment style" => {
        [
          [
            ACON::Helper::Table::Cell.new("<comment>Long Title</comment>", colspan: 3),
          ],
        ],
        [
          [
            ACON::Helper::Table::Cell.new("9971-5-0210-0", colspan: 3),
          ],
          ACON::Helper::Table::Separator.new,
          [
            "Dante Alighieri",
            "J. R. R. Tolkien",
            "J. R. R",
          ],
        ],
        "default",
        self.get_table_contents("default_colspan_and_table_cell_with_comment_style"),
        true,
      },
      "Default row with formatted cells containing a newline" => {
        [[] of String],
        [
          [
            ACON::Helper::Table::Cell.new("<error>Dont break\nhere</error>", colspan: 2),
          ],
          ACON::Helper::Table::Separator.new,
          [
            "foo",
            ACON::Helper::Table::Cell.new("<error>Dont break\nhere</error>", rowspan: 2),
          ],
          [
            "bar",
          ],
        ],
        "default",
        self.get_table_contents("default_formatted_row_with_line_breaks"),
        true,
      },
      "Default cells with rowspan and colspan with alignment" => {
        [
          ACON::Helper::Table::Cell.new("ISBN", style: ACON::Helper::Table::CellStyle.new(align: :right)),
          "Title",
          ACON::Helper::Table::Cell.new("Author", style: ACON::Helper::Table::CellStyle.new(align: :center)),
        ],
        [
          [
            ACON::Helper::Table::Cell.new("<fg=red>978</>", style: ACON::Helper::Table::CellStyle.new(align: :center)),
            "De Monarchia",
            ACON::Helper::Table::Cell.new(
              "Dante Alighieri \nspans multiple rows rows Dante Alighieri \nspans multiple rows rows",
              rowspan: 2,
              style: ACON::Helper::Table::CellStyle.new(align: :center)
            ),
          ],
          [
            "<info>99921-58-10-7</info>",
            "Divine Comedy",
          ],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("<error>test</error>", colspan: 2, style: ACON::Helper::Table::CellStyle.new(align: :center)),
            ACON::Helper::Table::Cell.new("tttt", style: ACON::Helper::Table::CellStyle.new(align: :right)),
          ],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_and_alignment"),
        false,
      },
      "Default cells with rowspan and colspan with fg,bg" => {
        [] of String,
        [
          [
            ACON::Helper::Table::Cell.new("<fg=red>978</>", style: ACON::Helper::Table::CellStyle.new(foreground: "black", background: "green")),
            "De Monarchia",
            ACON::Helper::Table::Cell.new("Dante Alighieri \nspans multiple rows rows Dante Alighieri \nspans multiple rows rows", rowspan: 2, style: ACON::Helper::Table::CellStyle.new(foreground: "red", background: "green", align: :center)),
          ],
          [
            "<info>99921-58-10-7</info>",
            "Divine Comedy",
          ],
          ACON::Helper::Table::Separator.new,
          [
            ACON::Helper::Table::Cell.new("<error>test</error>", colspan: 2, style: ACON::Helper::Table::CellStyle.new(foreground: "red", background: "green", align: :center)),
            ACON::Helper::Table::Cell.new("tttt", style: ACON::Helper::Table::CellStyle.new(foreground: "red", background: "green", align: :right)),
          ],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_and_fgbg"),
        true,
      },
      "Default cells with rowspan and colspan > 1 with custom cell format" => {
        [
          ACON::Helper::Table::Cell.new("ISBN", style: ACON::Helper::Table::CellStyle.new(format: "<fg=black;bg=cyan>%s</>")),
          "Title",
          "Author",
        ],
        [
          [
            "978-0521567817",
            "De Monarchia",
            ACON::Helper::Table::Cell.new("Dante Alighieri\nspans multiple rows", rowspan: 2, style: ACON::Helper::Table::CellStyle.new(format: "<info>%s</info>")),
          ],
          ["978-0804169127", "Divine Comedy"],
          [
            ACON::Helper::Table::Cell.new("test", colspan: 2, style: ACON::Helper::Table::CellStyle.new(format: "<error>%s</error>")),
            "tttt",
          ],
        ],
        "default",
        self.get_table_contents("default_cells_with_rowspan_and_colspan_and_custom_format"),
        true,
      },
    }
  end

  @[Pending]
  # TODO: Enable when multi byte string widths are supported
  def test_render_multi_byte : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["🍝"])
      .rows([[1234]])
      .style("default")
      .render

    self.output_content(output).should eq <<-TABLE
    +------+
    | 🍝   |
    +------+
    | 1234 |
    +------+

    TABLE
  end

  def test_render_table_cell_numeric_int_value : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .rows([[ACON::Helper::Table::Cell.new(1234)]])
      .render

    self.output_content(output).should eq <<-TABLE
    +------+
    | 1234 |
    +------+

    TABLE
  end

  def test_render_table_cell_numeric_float_value : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .rows([[ACON::Helper::Table::Cell.new(3.14)]])
      .render

    self.output_content(output).should eq <<-TABLE
    +------+
    | 3.14 |
    +------+

    TABLE
  end

  def test_render_custom_style : Nil
    style = ACON::Helper::Table::Style.new
    style
      .horizontal_border_chars('.')
      .vertical_border_chars('.')
      .default_crossing_char('.')

    ACON::Helper::Table.set_style_definition "dotfull", style
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["Foo"])
      .rows([["Bar"]])
      .style("dotfull")
      .render

    self.output_content(output).should eq <<-TABLE
    .......
    . Foo .
    .......
    . Bar .
    .......

    TABLE
  end

  def test_render_multiple_times : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .rows([[ACON::Helper::Table::Cell.new("foo", colspan: 2)]])
      .render

    table.render
    table.render

    self.output_content(output).should eq <<-TABLE
    +----+---+
    | foo    |
    +----+---+
    +----+---+
    | foo    |
    +----+---+
    +----+---+
    | foo    |
    +----+---+

    TABLE
  end

  def test_column_style : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
        ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"],
      ])

    style = ACON::Helper::Table::Style.new
      .align(:right)

    table.column_style 3, style
    table.column_style(3).should eq style

    table.render

    self.output_content(output).should eq <<-TABLE
    +---------------+----------------------+-----------------+--------+
    | ISBN          | Title                | Author          |  Price |
    +---------------+----------------------+-----------------+--------+
    | 99921-58-10-7 | Divine Comedy        | Dante Alighieri |   9.95 |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+

    TABLE
  end

  def test_column_width : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
        ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"],
      ])
      .column_width(0, 15)
      .column_width(3, 10)

    style = ACON::Helper::Table::Style.new
      .align(:right)

    table.column_style 3, style

    table.render

    self.output_content(output).should eq <<-TABLE
    +-----------------+----------------------+-----------------+------------+
    | ISBN            | Title                | Author          |      Price |
    +-----------------+----------------------+-----------------+------------+
    | 99921-58-10-7   | Divine Comedy        | Dante Alighieri |       9.95 |
    | 9971-5-0210-0   | A Tale of Two Cities | Charles Dickens |     139.25 |
    +-----------------+----------------------+-----------------+------------+

    TABLE
  end

  def test_column_widths : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
        ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"],
      ])
      .column_widths(15, 0, -1, 10)

    style = ACON::Helper::Table::Style.new
      .align(:right)

    table.column_style 3, style

    table.render

    self.output_content(output).should eq <<-TABLE
    +-----------------+----------------------+-----------------+------------+
    | ISBN            | Title                | Author          |      Price |
    +-----------------+----------------------+-----------------+------------+
    | 99921-58-10-7   | Divine Comedy        | Dante Alighieri |       9.95 |
    | 9971-5-0210-0   | A Tale of Two Cities | Charles Dickens |     139.25 |
    +-----------------+----------------------+-----------------+------------+

    TABLE
  end

  def test_column_widths_enumerable : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
        ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"],
      ])
      .column_widths({15, 0, -1, 10})

    style = ACON::Helper::Table::Style.new
      .align(:right)

    table.column_style 3, style

    table.render

    self.output_content(output).should eq <<-TABLE
    +-----------------+----------------------+-----------------+------------+
    | ISBN            | Title                | Author          |      Price |
    +-----------------+----------------------+-----------------+------------+
    | 99921-58-10-7   | Divine Comedy        | Dante Alighieri |       9.95 |
    | 9971-5-0210-0   | A Tale of Two Cities | Charles Dickens |     139.25 |
    +-----------------+----------------------+-----------------+------------+

    TABLE
  end

  def test_column_max_width : Nil
    table = ACON::Helper::Table.new output = self.io_output
    table
      .rows([
        ["Divine Comedy", "A Tale of Two Cities", "The Lord of the Rings", "And Then There Were None"],
      ])
      .column_max_width(1, 5)
      .column_max_width(2, 10)
      .column_max_width(3, 15)
      .render

    self.output_content(output).should eq <<-TABLE
    +---------------+-------+------------+-----------------+
    | Divine Comedy | A Tal | The Lord o | And Then There  |
    |               | e of  | f the Ring | Were None       |
    |               | Two C | s          |                 |
    |               | ities |            |                 |
    +---------------+-------+------------+-----------------+

    TABLE
  end

  def test_column_max_width_with_headers : Nil
    table = ACON::Helper::Table.new output = self.io_output

    table
      .headers([
        [
          "Publication",
          "Very long header with a lot of information",
        ],
      ])
      .rows([
        [
          "1954",
          "The Lord of the Rings, by J.R.R. Tolkien",
        ],
      ])
      .column_max_width(1, 30)
      .render

    self.output_content(output).should eq <<-TABLE
    +-------------+--------------------------------+
    | Publication | Very long header with a lot of |
    |             | information                    |
    +-------------+--------------------------------+
    | 1954        | The Lord of the Rings, by J.R. |
    |             | R. Tolkien                     |
    +-------------+--------------------------------+

    TABLE
  end

  def test_column_max_width_trailing_backslash : Nil
    table = ACON::Helper::Table.new output = self.io_output

    table
      .rows([
        ["1234\\6"],
      ])
      .column_max_width(0, 5)
      .render

    self.output_content(output).should eq <<-'TABLE'
    +-------+
    | 1234\ |
    | 6     |
    +-------+

    TABLE
  end

  def test_render_max_width_colspan : Nil
    ACON::Helper::Table.new(output = self.io_output)
      .rows([
        [ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, <fg=white;bg=green>consectetur</> adipiscing elit, <fg=white;bg=red>sed</> do <fg=white;bg=red>eiusmod</> tempor", colspan: 3)],
        ACON::Helper::Table::Separator.new,
        [ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor", colspan: 3)],
        ACON::Helper::Table::Separator.new,
        [ACON::Helper::Table::Cell.new("Lorem ipsum <fg=white;bg=red>dolor</> sit amet, consectetur ", colspan: 2), "hello world"],
        ACON::Helper::Table::Separator.new,
        ["hello <fg=white;bg=green>world</>", ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, <fg=white;bg=green>consectetur</> adipiscing elit", colspan: 2)],
        ACON::Helper::Table::Separator.new,
        ["hello ", ACON::Helper::Table::Cell.new("world", colspan: 1), "Lorem ipsum dolor sit amet, consectetur"],
        ACON::Helper::Table::Separator.new,
        ["Athena ", ACON::Helper::Table::Cell.new("Test", colspan: 1), "Lorem <fg=white;bg=green>ipsum</> dolor sit amet, consectetur"],
      ])
      .column_max_width(0, 15)
      .column_max_width(1, 15)
      .column_max_width(2, 15)
      .render

    self.output_content(output).should eq <<-'TABLE'
    +-----------------+-----------------+-----------------+
    | Lorem ipsum dolor sit amet, consectetur adipi       |
    | scing elit, sed do eiusmod tempor                   |
    +-----------------+-----------------+-----------------+
    | Lorem ipsum dolor sit amet, consectetur adipi       |
    | scing elit, sed do eiusmod tempor                   |
    +-----------------+-----------------+-----------------+
    | Lorem ipsum dolor sit amet, co    | hello world     |
    | nsectetur                         |                 |
    +-----------------+-----------------+-----------------+
    | hello world     | Lorem ipsum dolor sit amet, co    |
    |                 | nsectetur adipiscing elit         |
    +-----------------+-----------------+-----------------+
    | hello           | world           | Lorem ipsum dol |
    |                 |                 | or sit amet, co |
    |                 |                 | nsectetur       |
    +-----------------+-----------------+-----------------+
    | Athena          | Test            | Lorem ipsum dol |
    |                 |                 | or sit amet, co |
    |                 |                 | nsectetur       |
    +-----------------+-----------------+-----------------+

    TABLE
  end

  def test_append_row : Nil
    sections = [] of ACON::Output::Section

    output = self.io_output true

    table = ACON::Helper::Table.new ACON::Output::Section.new output.io, sections, output.verbosity, output.decorated?, ACON::Formatter::Output.new

    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
      ])
      .render

    table.append_row ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"]
    table.append_row "9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"

    self.output_content(output).should eq <<-TABLE
    +---------------+---------------+-----------------+-------+
    |[32m ISBN          [0m|[32m Title         [0m|[32m Author          [0m|[32m Price [0m|
    +---------------+---------------+-----------------+-------+
    | 99921-58-10-7 | Divine Comedy | Dante Alighieri | 9.95  |
    +---------------+---------------+-----------------+-------+
    [5A[0J+---------------+----------------------+-----------------+--------+
    |[32m ISBN          [0m|[32m Title                [0m|[32m Author          [0m|[32m Price  [0m|
    +---------------+----------------------+-----------------+--------+
    | 99921-58-10-7 | Divine Comedy        | Dante Alighieri | 9.95   |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+
    [6A[0J+---------------+----------------------+-----------------+--------+
    |[32m ISBN          [0m|[32m Title                [0m|[32m Author          [0m|[32m Price  [0m|
    +---------------+----------------------+-----------------+--------+
    | 99921-58-10-7 | Divine Comedy        | Dante Alighieri | 9.95   |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+

    TABLE
  end

  def test_append_row_doesnt_clear_if_not_rendered : Nil
    sections = [] of ACON::Output::Section

    output = self.io_output true

    table = ACON::Helper::Table.new ACON::Output::Section.new output.io, sections, output.verbosity, output.decorated?, ACON::Formatter::Output.new

    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
      ])

    table.append_row "9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"

    self.output_content(output).should eq <<-TABLE
    +---------------+----------------------+-----------------+--------+
    |[32m ISBN          [0m|[32m Title                [0m|[32m Author          [0m|[32m Price  [0m|
    +---------------+----------------------+-----------------+--------+
    | 99921-58-10-7 | Divine Comedy        | Dante Alighieri | 9.95   |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+

    TABLE
  end

  def test_append_row_without_decoration : Nil
    sections = [] of ACON::Output::Section

    output = self.io_output

    table = ACON::Helper::Table.new ACON::Output::Section.new output.io, sections, output.verbosity, output.decorated?, ACON::Formatter::Output.new

    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
      ])
      .render

    table.append_row "9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"

    self.output_content(output).should eq <<-TABLE
    +---------------+---------------+-----------------+-------+
    | ISBN          | Title         | Author          | Price |
    +---------------+---------------+-----------------+-------+
    | 99921-58-10-7 | Divine Comedy | Dante Alighieri | 9.95  |
    +---------------+---------------+-----------------+-------+
    +---------------+----------------------+-----------------+--------+
    | ISBN          | Title                | Author          | Price  |
    +---------------+----------------------+-----------------+--------+
    | 99921-58-10-7 | Divine Comedy        | Dante Alighieri | 9.95   |
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+

    TABLE
  end

  def test_append_row_first_row : Nil
    sections = [] of ACON::Output::Section

    output = self.io_output true

    table = ACON::Helper::Table.new ACON::Output::Section.new output.io, sections, output.verbosity, output.decorated?, ACON::Formatter::Output.new

    table
      .headers(["ISBN", "Title", "Author", "Price"])
      .render

    table.append_row "9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"

    self.output_content(output).should eq <<-TABLE
    +------+-------+--------+-------+
    |[32m ISBN [0m|[32m Title [0m|[32m Author [0m|[32m Price [0m|
    +------+-------+--------+-------+
    [3A[0J+---------------+----------------------+-----------------+--------+
    |[32m ISBN          [0m|[32m Title                [0m|[32m Author          [0m|[32m Price  [0m|
    +---------------+----------------------+-----------------+--------+
    | 9971-5-0210-0 | A Tale of Two Cities | Charles Dickens | 139.25 |
    +---------------+----------------------+-----------------+--------+

    TABLE
  end

  def test_append_row_no_section_output : Nil
    table = ACON::Helper::Table.new self.io_output

    expect_raises ACON::Exceptions::Logic, "Appending a row is only supported when using a Athena::Console::Output::Section output, got Athena::Console::Output::IO." do
      table.append_row "9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"
    end
  end

  def test_missing_table_definition : Nil
    table = ACON::Helper::Table.new self.io_output

    expect_raises ACON::Exceptions::InvalidArgument, "The table style 'absent' is not defined." do
      table.style "absent"
    end
  end

  def test_style_definition_missing : Nil
    expect_raises ACON::Exceptions::InvalidArgument, "The table style 'absent' is not defined." do
      ACON::Helper::Table.style_definition "absent"
    end
  end

  @[DataProvider("title_provider")]
  def test_render_titles(header_title : String, footer_title : String, style : String, expected : String) : Nil
    ACON::Helper::Table.new(output = self.io_output)
      .header_title(header_title)
      .footer_title(footer_title)
      .headers(["ISBN", "Title", "Author"])
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
        ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
        ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
        ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
      ])
      .style(style)
      .render

    self.output_content(output).should eq expected
  end

  def title_provider : Tuple
    {
      {
        "Books",
        "Page 1/2",
        "default",
        <<-'TABLE'
        +---------------+----------- Books --------+------------------+
        | ISBN          | Title                    | Author           |
        +---------------+--------------------------+------------------+
        | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
        | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
        | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
        | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
        +---------------+--------- Page 1/2 -------+------------------+

        TABLE
      },
      {
        "Multiline\nheader\nhere",
        "footer",
        "default",
        <<-'TABLE'
        +---------------+--- Multiline
        header
        here +------------------+
        | ISBN          | Title                    | Author           |
        +---------------+--------------------------+------------------+
        | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
        | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
        | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
        | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
        +---------------+---------- footer --------+------------------+

        TABLE
      },
      {
        "Books",
        "Page 1/2",
        "box",
        <<-'TABLE'
        ┌───────────────┬─────────── Books ────────┬──────────────────┐
        │ ISBN          │ Title                    │ Author           │
        ├───────────────┼──────────────────────────┼──────────────────┤
        │ 99921-58-10-7 │ Divine Comedy            │ Dante Alighieri  │
        │ 9971-5-0210-0 │ A Tale of Two Cities     │ Charles Dickens  │
        │ 960-425-059-0 │ The Lord of the Rings    │ J. R. R. Tolkien │
        │ 80-902734-1-6 │ And Then There Were None │ Agatha Christie  │
        └───────────────┴───────── Page 1/2 ───────┴──────────────────┘

        TABLE
      },
      {
        "Boooooooooooooooooooooooooooooooooooooooooooooooooooooooks",
        "Page 1/999999999999999999999999999999999999999999999999999",
        "default",
        <<-'TABLE'
        +- Booooooooooooooooooooooooooooooooooooooooooooooooooooo... -+
        | ISBN          | Title                    | Author           |
        +---------------+--------------------------+------------------+
        | 99921-58-10-7 | Divine Comedy            | Dante Alighieri  |
        | 9971-5-0210-0 | A Tale of Two Cities     | Charles Dickens  |
        | 960-425-059-0 | The Lord of the Rings    | J. R. R. Tolkien |
        | 80-902734-1-6 | And Then There Were None | Agatha Christie  |
        +- Page 1/99999999999999999999999999999999999999999999999... -+

        TABLE
      },
    }
  end

  def test_render_titles_no_headers : Nil
    ACON::Helper::Table.new(output = self.io_output)
      .header_title("Reproducer")
      .rows([
        ["Value", "123-456"],
        ["Some other value", "789-0"],
      ])
      .render

    self.output_content(output).should eq <<-TABLE
    +-------- Reproducer --------+
    | Value            | 123-456 |
    | Some other value | 789-0   |
    +------------------+---------+

    TABLE
  end

  def test_box_style_with_colspan : Nil
    boxed = ACON::Helper::Table::Style.new
      .horizontal_border_chars('─')
      .vertical_border_chars('│')
      .crossing_chars('┼', '┌', '┬', '┐', '┤', '┘', '┴', '└', '├')

    ACON::Helper::Table.new(output = self.io_output)
      .style(boxed)
      .headers("ISBN", "Title", "Author")
      .rows([
        ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
        ACON::Helper::Table::Separator.new,
        [ACON::Helper::Table::Cell.new("This value spans 3 columns.", colspan: 3)],
      ])
      .render

    self.output_content(output).should eq <<-TABLE
    ┌───────────────┬───────────────┬─────────────────┐
    │ ISBN          │ Title         │ Author          │
    ├───────────────┼───────────────┼─────────────────┤
    │ 99921-58-10-7 │ Divine Comedy │ Dante Alighieri │
    ├───────────────┼───────────────┼─────────────────┤
    │ This value spans 3 columns.                     │
    └───────────────┴───────────────┴─────────────────┘

    TABLE
  end

  @[DataProvider("horizontal_provider")]
  def test_render_horizontal(headers, rows, expected)
    ACON::Helper::Table.new(output = self.io_output)
      .headers(headers)
      .rows(rows)
      .horizontal
      .render

    self.output_content(output).should eq expected
  end

  def horizontal_provider : Tuple
    {
      {
        %w(foo bar baz),
        [
          %w(one two tree),
          %w(1 2 3),
        ],
        <<-'TABLE'
        +-----+------+---+
        | foo | one  | 1 |
        | bar | two  | 2 |
        | baz | tree | 3 |
        +-----+------+---+

        TABLE
      },
      {
        %w(foo bar baz),
        [
          %w(one two),
          %w(1),
        ],
        <<-'TABLE'
        +-----+-----+---+
        | foo | one | 1 |
        | bar | two |   |
        | baz |     |   |
        +-----+-----+---+

        TABLE
      },
      {
        %w(foo bar baz),
        [
          %w(one two tree),
          ACON::Helper::Table::Separator.new,
          %w(1 2 3),
        ],
        <<-'TABLE'
        +-----+------+---+
        | foo | one  | 1 |
        | bar | two  | 2 |
        | baz | tree | 3 |
        +-----+------+---+

        TABLE
      },
    }
  end

  @[DataProvider("vertical_provider")]
  def test_render_vertical(headers, rows, expected, style : String, header_title, footer_title)
    ACON::Helper::Table.new(output = self.io_output)
      .headers(headers)
      .rows(rows)
      .style(style)
      .header_title(header_title)
      .footer_title(footer_title)
      .vertical
      .render

    self.output_content(output).should eq expected
  end

  def vertical_provider : Hash
    books = [
      ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
      ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens", "139.25"],
    ]

    {
      "With header for all" => {
        %w(ISBN Title Author Price),
        books,
        <<-'TABLE',
        +------------------------------+
        |   ISBN: 99921-58-10-7        |
        |  Title: Divine Comedy        |
        | Author: Dante Alighieri      |
        |  Price: 9.95                 |
        |------------------------------|
        |   ISBN: 9971-5-0210-0        |
        |  Title: A Tale of Two Cities |
        | Author: Charles Dickens      |
        |  Price: 139.25               |
        +------------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With header for none" => {
        %w(),
        books,
        <<-'TABLE',
        +----------------------+
        | 99921-58-10-7        |
        | Divine Comedy        |
        | Dante Alighieri      |
        | 9.95                 |
        |----------------------|
        | 9971-5-0210-0        |
        | A Tale of Two Cities |
        | Charles Dickens      |
        | 139.25               |
        +----------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With header for some" => {
        %w(ISBN Title Author),
        books,
        <<-'TABLE',
        +------------------------------+
        |   ISBN: 99921-58-10-7        |
        |  Title: Divine Comedy        |
        | Author: Dante Alighieri      |
        |       : 9.95                 |
        |------------------------------|
        |   ISBN: 9971-5-0210-0        |
        |  Title: A Tale of Two Cities |
        | Author: Charles Dickens      |
        |       : 139.25               |
        +------------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With row for some headers" => {
        %w(foo bar baz),
        [
          %w(one two),
          %w(1),
        ],
        <<-'TABLE',
        +----------+
        | foo: one |
        | bar: two |
        | baz:     |
        |----------|
        | foo: 1   |
        | bar:     |
        | baz:     |
        +----------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With table separator" => {
        %w(foo bar baz),
        [
          %w(one two tree),
          ACON::Helper::Table::Separator.new,
          %w(1 2 3),
        ],
        <<-'TABLE',
        +-----------+
        | foo: one  |
        | bar: two  |
        | baz: tree |
        |-----------|
        | foo: 1    |
        | bar: 2    |
        | baz: 3    |
        +-----------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With line breaks" => {
        %w(ISBN Title Author Price),
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri", "9.95"],
          ["9971-5-0210-0", "A Tale\nof Two Cities", "Charles Dickens", "139.25"],
        ],
        <<-'TABLE',
        +-------------------------+
        |   ISBN: 99921-58-10-7   |
        |  Title: Divine Comedy   |
        | Author: Dante Alighieri |
        |  Price: 9.95            |
        |-------------------------|
        |   ISBN: 9971-5-0210-0   |
        |  Title: A Tale          |
        | of Two Cities           |
        | Author: Charles Dickens |
        |  Price: 139.25          |
        +-------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With formatting tags" => {
        %w(ISBN Title Author),
        [
          ["<info>99921-58-10-7</info>", "<error>Divine Comedy</error>", "<fg=blue;bg=white>Dante Alighieri</fg=blue;bg=white>"],
          ["9971-5-0210-0", "A Tale of Two Cities", "<info>Charles Dickens</>"],
        ],
        <<-'TABLE',
        +------------------------------+
        |   ISBN: 99921-58-10-7        |
        |  Title: Divine Comedy        |
        | Author: Dante Alighieri      |
        |------------------------------|
        |   ISBN: 9971-5-0210-0        |
        |  Title: A Tale of Two Cities |
        | Author: Charles Dickens      |
        +------------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With colspan" => {
        %w(ISBN Title Author),
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          [ACON::Helper::Table::Cell.new("Cupiditate dicta atque porro, tempora exercitationem modi animi nulla nemo vel nihil!", colspan: 3)],
          ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
        ],
        <<-'TABLE',
        +---------------------------------------------------------------------------------------+
        |   ISBN: 99921-58-10-7                                                                 |
        |  Title: Divine Comedy                                                                 |
        | Author: Dante Alighieri                                                               |
        |---------------------------------------------------------------------------------------|
        | Cupiditate dicta atque porro, tempora exercitationem modi animi nulla nemo vel nihil! |
        |---------------------------------------------------------------------------------------|
        |   ISBN: 9971-5-0210-0                                                                 |
        |  Title: A Tale of Two Cities                                                          |
        | Author: Charles Dickens                                                               |
        +---------------------------------------------------------------------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "With colspans but no header" => {
        %w(),
        [
          [ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, <fg=white;bg=green>consectetur</> adipiscing elit, <fg=white;bg=red>sed</> do <fg=white;bg=red>eiusmod</> tempor", colspan: 3)],
          ACON::Helper::Table::Separator.new,
          [ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor", colspan: 3)],
          ACON::Helper::Table::Separator.new,
          [ACON::Helper::Table::Cell.new("Lorem ipsum <fg=white;bg=red>dolor</> sit amet, consectetur ", colspan: 2), "hello world"],
          ACON::Helper::Table::Separator.new,
          ["hello <fg=white;bg=green>world</>", ACON::Helper::Table::Cell.new("Lorem ipsum dolor sit amet, <fg=white;bg=green>consectetur</> adipiscing elit", colspan: 2)],
          ACON::Helper::Table::Separator.new,
          ["hello ", ACON::Helper::Table::Cell.new("world", colspan: 1), "Lorem ipsum dolor sit amet, consectetur"],
          ACON::Helper::Table::Separator.new,
          ["Symfony ", ACON::Helper::Table::Cell.new("Test", colspan: 1), "Lorem <fg=white;bg=green>ipsum</> dolor sit amet, consectetur"],
        ],
        <<-'TABLE',
        +--------------------------------------------------------------------------------+
        | Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor |
        |--------------------------------------------------------------------------------|
        | Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor |
        |--------------------------------------------------------------------------------|
        | Lorem ipsum dolor sit amet, consectetur                                        |
        | hello world                                                                    |
        |--------------------------------------------------------------------------------|
        | hello world                                                                    |
        | Lorem ipsum dolor sit amet, consectetur adipiscing elit                        |
        |--------------------------------------------------------------------------------|
        | hello                                                                          |
        | world                                                                          |
        | Lorem ipsum dolor sit amet, consectetur                                        |
        |--------------------------------------------------------------------------------|
        | Symfony                                                                        |
        | Test                                                                           |
        | Lorem ipsum dolor sit amet, consectetur                                        |
        +--------------------------------------------------------------------------------+

        TABLE
        "default",
        nil,
        nil,
      },
      "Borderless style" => {
        %w(ISBN Title Author Price),
        books,
        self.get_table_contents("borderless_vertical"),
        "borderless",
        nil,
        nil,
      },
      "Compact style" => {
        %w(ISBN Title Author Price),
        books,
        self.get_table_contents("compact_vertical"),
        "compact",
        nil,
        nil,
      },
      "Suggested style" => {
        %w(ISBN Title Author Price),
        books,
        self.get_table_contents("suggested_vertical"),
        "suggested",
        nil,
        nil,
      },
      "Box style" => {
        %w(ISBN Title Author Price),
        books,
        <<-'TABLE',
        ┌──────────────────────────────┐
        │   ISBN: 99921-58-10-7        │
        │  Title: Divine Comedy        │
        │ Author: Dante Alighieri      │
        │  Price: 9.95                 │
        │──────────────────────────────│
        │   ISBN: 9971-5-0210-0        │
        │  Title: A Tale of Two Cities │
        │ Author: Charles Dickens      │
        │  Price: 139.25               │
        └──────────────────────────────┘

        TABLE
        "box",
        nil,
        nil,
      },
      "Double box style" => {
        %w(ISBN Title Author Price),
        books,
        <<-'TABLE',
        ╔══════════════════════════════╗
        ║   ISBN: 99921-58-10-7        ║
        ║  Title: Divine Comedy        ║
        ║ Author: Dante Alighieri      ║
        ║  Price: 9.95                 ║
        ║──────────────────────────────║
        ║   ISBN: 9971-5-0210-0        ║
        ║  Title: A Tale of Two Cities ║
        ║ Author: Charles Dickens      ║
        ║  Price: 139.25               ║
        ╚══════════════════════════════╝

        TABLE
        "double-box",
        nil,
        nil,
      },
      "With titles" => {
        %w(ISBN Title Author Price),
        books,
        <<-'TABLE',
        +----------- Books ------------+
        |   ISBN: 99921-58-10-7        |
        |  Title: Divine Comedy        |
        | Author: Dante Alighieri      |
        |  Price: 9.95                 |
        |------------------------------|
        |   ISBN: 9971-5-0210-0        |
        |  Title: A Tale of Two Cities |
        | Author: Charles Dickens      |
        |  Price: 139.25               |
        +---------- Page 1/2 ----------+

        TABLE
        "default",
        "Books",
        "Page 1/2",
      },
    }
  end

  private def output_content(output : ACON::Output::IO) : String
    output.to_s
  end

  private def io_output(decorated : Bool = false) : ACON::Output::IO
    ACON::Output::IO.new @output, decorated: decorated
  end
end
