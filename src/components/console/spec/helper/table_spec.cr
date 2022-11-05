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
  def test_render(headers : Array(String), rows, style : String, expected : String, decorated : Bool) : Nil
    table = ACON::Helper::Table.new output = self.io_output decorated
    table
      .headers(headers)
      .rows(rows)
      .style(style)

    table.render

    self.output_content(output).should eq expected
  end

  def render_provider : Tuple
    books = [
      ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
      ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
      ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
      ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
    ]

    {
      {
        ["ISBN", "Title", "Author"],
        books,
        style = "default",
        self.get_table_contents(style),
        false,
      },
      {
        ["ISBN", "Title", "Author"],
        books,
        style = "compact",
        self.get_table_contents(style),
        false,
      },
      {
        ["ISBN", "Title", "Author"],
        books,
        style = "borderless",
        self.get_table_contents(style),
        false,
      },
      {
        ["ISBN", "Title", "Author"],
        books,
        style = "box",
        self.get_table_contents(style),
        false,
      },
      {
        ["ISBN", "Title", "Author"],
        [
          ["99921-58-10-7", "Divine Comedy", "Dante Alighieri"],
          ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
          ACON::Helper::Table::TableSeperator.new,
          ["960-425-059-0", "The Lord of the Rings", "J. R. R. Tolkien"],
          ["80-902734-1-6", "And Then There Were None", "Agatha Christie"],
        ],
        "double-box",
        self.get_table_contents("double_box_seperator"),
        false,
      },
      {
        ["ISBN", "Title"],
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
      {
        [] of String,
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
      {
        ["ISBN", "Title", "Author"],
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
      {
        ["ISBN", "Title"],
        [] of String,
        "default",
        self.get_table_contents("default_no_rows"),
        false,
      },
      {
        [] of String,
        [] of String,
        "default",
        "",
        false,
      },
      # Tags used for output formatting
      {
        ["ISBN", "Title", "Author"],
        [
          ["<info>99921-58-10-7</info>", "<error>Divine Comedy</error>", "<fg=blue;bg=white>Dante Alighieri</fg=blue;bg=white>"],
          ["9971-5-0210-0", "A Tale of Two Cities", "<info>Charles Dickens</>"],
        ],
        "default",
        self.get_table_contents("default_cells_with_formatting_tags"),
        false,
      },
      # Tags not used for output formatting
      {
        ["ISBN", "Title", "Author"],
        [
          ["<strong>99921-58-10-700</strong>", "<f>Divine Com</f>", "Dante Alighieri"],
          ["9971-5-0210-0", "A Tale of Two Cities", "Charles Dickens"],
        ],
        "default",
        self.get_table_contents("default_cells_with_non_formatting_tags"),
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
