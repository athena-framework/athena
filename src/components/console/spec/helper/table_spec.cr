require "../spec_helper"

@[ASPEC::TestCase::Focus]
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

  @[DataProvider("render_provider")]
  def test_render(headers, rows, style : String, expected : String, decorated : Bool) : Nil
    table = ACON::Helper::Table.new output = self.io_output decorated
    table
      .headers(headers)
      .rows(rows)
      .style(style)

    table.render

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
          ACON::Helper::Table::TableSeparator.new,
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
          ACON::Helper::Table::TableSeparator.new,
          [
            ACON::Helper::Table::Cell.new("Divine Comedy(Dante Alighieri)", colspan: 3),
          ],
          ACON::Helper::Table::TableSeparator.new,
          [
            ACON::Helper::Table::Cell.new("Arduino: A Quick-Start Guide", colspan: 2),
            "Mark Schmidt",
          ],
          ACON::Helper::Table::TableSeparator.new,
          [
            "9971-5-0210-0",
            ACON::Helper::Table::Cell.new("A Tale of \nTwo Cities", colspan: 2),
          ],
          ACON::Helper::Table::TableSeparator.new,
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
          ACON::Helper::Table::TableSeparator.new,
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
          ACON::Helper::Table::TableSeparator.new,
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
          ACON::Helper::Table::TableSeparator.new,
          [
            "Dante Alighieri",
            ACON::Helper::Table::Cell.new("9971\n-5-\n021\n0-0", rowspan: 2, colspan: 2),
          ],
          ["Charles Dickens"],
          ACON::Helper::Table::TableSeparator.new,
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
          [ACON::Helper::Table::TableSeparator.new],
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
    }
  end

  private def output_content(output : ACON::Output::IO) : String
    output.to_s
  end

  private def io_output(decorated : Bool) : ACON::Output::IO
    ACON::Output::IO.new @output, decorated: decorated
  end
end
