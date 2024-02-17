require "../spec_helper"

struct AthenaStyleTest < ASPEC::TestCase
  @col_size : String?

  def initialize
    @col_size = ENV["COLUMNS"]?
    ENV["COLUMNS"] = "121"
  end

  def tear_down : Nil
    if size = @col_size
      ENV["COLUMNS"] = size
    else
      ENV.delete "COLUMNS"
    end
  end

  private def assert_file_equals_string(filepath : String, string : String, *, file : String = __FILE__, line : Int32 = __LINE__) : Nil
    normalized_path = File.join __DIR__, "..", "fixtures", filepath
    string.should match(Regex.new(File.read(normalized_path).gsub EOL, "\n")), file: file, line: line
  end

  def test_error_style : Nil
    error_output = ACON::Output::IO.new io = IO::Memory.new
    output = ACON::Output::ConsoleOutput.new
    output.stderr = error_output

    style = ACON::Style::Athena.new ACON::Input::Hash.new({} of String => String), output
    style.error_style.puts "foo"

    io.to_s.should eq "foo#{EOL}"
  end

  def test_error_style_non_console_output : Nil
    output = ACON::Output::IO.new io = IO::Memory.new

    style = ACON::Style::Athena.new ACON::Input::Hash.new({} of String => String), output
    style.error_style.puts "foo"

    io.to_s.should eq "foo#{EOL}"
  end

  @[DataProvider("output_provider")]
  def test_outputs(command_proc : ACON::Commands::Generic::Proc, file_path : String) : Nil
    command = ACON::Commands::Generic.new "foo", &command_proc

    tester = ACON::Spec::CommandTester.new command

    tester.execute interactive: false, decorated: false
    self.assert_file_equals_string file_path, tester.display true
  end

  def output_provider : Hash
    {
      "Single blank line at start with block element" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).caution "Lorem ipsum dolor sit amet"

          ACON::Command::Status::SUCCESS
        end),
        "style/block.txt",
      },
      "Single blank line between titles and blocks" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.title "Title"
          style.warning "Lorem ipsum dolor sit amet"
          style.title "Title"

          ACON::Command::Status::SUCCESS
        end),
        "style/title_block.txt",
      },
      "Single blank line between blocks" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.warning "Warning"
          style.caution "Caution"
          style.error "Error"
          style.success "Success"
          style.note "Note"
          style.info "Info"
          style.block "Custom block", "CUSTOM", style: "fg=white;bg=green", prefix: "X ", padding: true

          ACON::Command::Status::SUCCESS
        end),
        "style/blocks.txt",
      },
      "Single blank line between titles" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.title "First title"
          style.title "Second title"

          ACON::Command::Status::SUCCESS
        end),
        "style/titles.txt",
      },
      "Single blank line after any text and a title" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.print "Lorem ipsum dolor sit amet"
          style.title "First title"

          style.puts "Lorem ipsum dolor sit amet"
          style.title "Second title"

          style.print "Lorem ipsum dolor sit amet"
          style.print ""
          style.title "Third title"

          # Handle edge case by appending empty strings to history
          style.print "Lorem ipsum dolor sit amet"
          style.print({"", "", ""})
          style.title "Fourth title"

          # Ensure manual control over number of blank lines
          style.puts "Lorem ipsum dolor sit amet"
          style.puts({"", ""}) # Should print 1 extra newline
          style.title "Fifth title"

          style.puts "Lorem ipsum dolor sit amet"
          style.new_line 2 # Should print 1 extra newline
          style.title "Sixth title"

          ACON::Command::Status::SUCCESS
        end),
        "style/titles_text.txt",
      },
      "Proper line endings before outputting a text block" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.puts "Lorem ipsum dolor sit amet"
          style.listing "Lorem ipsum dolor sit amet", "consectetur adipiscing elit"

          # When using print
          style.print "Lorem ipsum dolor sit amet"
          style.listing "Lorem ipsum dolor sit amet", "consectetur adipiscing elit"

          style.print "Lorem ipsum dolor sit amet"
          style.text({"Lorem ipsum dolor sit amet", "consectetur adipiscing elit"})

          style.new_line

          style.print "Lorem ipsum dolor sit amet"
          style.comment({"Lorem ipsum dolor sit amet", "consectetur adipiscing elit"})

          ACON::Command::Status::SUCCESS
        end),
        "style/block_line_endings.txt",
      },
      "Proper blank line after text block with block" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.listing "Lorem ipsum dolor sit amet", "consectetur adipiscing elit"
          style.success "Lorem ipsum dolor sit amet"

          ACON::Command::Status::SUCCESS
        end),
        "style/text_block_blank_line.txt",
      },
      "Questions do not output anything when input is non-interactive" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.title "Title"
          style.ask_hidden "Hidden question"
          style.choice "Choice question with default", {"choice1", "choice2"}, "choice1"
          style.confirm "Confirmation with yes default", true
          style.text "Duis aute irure dolor in reprehenderit in voluptate velit esse"

          ACON::Command::Status::SUCCESS
        end),
        "style/non_interactive_question.txt",
      },
      # TODO: Test table formatting with multiple headers + TableCell
      "Lines are aligned to the beginning of the first line in a multi-line block" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).block({"Custom block", "Second custom block line"}, "CUSTOM", style: "fg=white;bg=green", prefix: "X ", padding: true)

          ACON::Command::Status::SUCCESS
        end),
        "style/multi_line_block.txt",
      },
      "Lines are aligned to the beginning of the first line in a very long line block" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).block(
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum",
            "CUSTOM",
            style: "fg=white;bg=green",
            prefix: "X ",
            padding: true
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/long_line_block.txt",
      },
      "Long lines are wrapped within a block" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).block(
            "Lopadotemachoselachogaleokranioleipsanodrimhypotrimmatosilphioparaomelitokatakechymenokichlepikossyphophattoperisteralektryonoptekephalliokigklopeleiolagoiosiraiobaphetraganopterygon",
            "CUSTOM",
            style: "fg=white;bg=green",
            prefix: " § ",
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/long_line_block_wrapping.txt",
      },
      "Lines are aligned to the first line and start with '//' in a very long line comment" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).comment(
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/long_line_comment.txt",
      },
      "Nested tags have no effect on the color of the '//' prefix" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          output.decorated = true
          ACON::Style::Athena.new(input, output).comment(
            "Árvíztűrőtükörfúrógép 🎼 Lorem ipsum dolor sit <comment>💕 amet, consectetur adipisicing elit, sed do eiusmod tempor incididu labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</comment> Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum"
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/long_line_comment_decorated.txt",
      },
      "Block behaves properly with a prefix and without type" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).block(
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum",
            prefix: "$ "
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/block_prefix_no_type.txt",
      },
      "Block behaves properly with a type and without prefix" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          ACON::Style::Athena.new(input, output).block(
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum",
            type: "TEST"
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/block_no_prefix_type.txt",
      },
      "Block output is properly formatted with even padding lines" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          output.decorated = true
          ACON::Style::Athena.new(input, output).success(
            "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum",
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/block_padding.txt",
      },
      "Handles trailing backslashes" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.title "Title ending with \\"
          style.section "Section ending with \\"

          ACON::Command::Status::SUCCESS
        end),
        "style/backslashes.txt",
      },
      "definition list" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style
            .definition_list(
              {"foo" => "bar"},
              ACON::Helper::Table::Separator.new,
              "this is a title",
              ACON::Helper::Table::Separator.new,
              {"foo2" => "bar2"}
            )

          ACON::Command::Status::SUCCESS
        end),
        "style/definition_list.txt",
      },
      "horizontal table" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.horizontal_table(["a", "b", "c", "d"], [[1, 2, 3], [4, 5], [7, 8, 9]])

          ACON::Command::Status::SUCCESS
        end),
        "style/horizontal_table.txt",
      },
      "Closing tag is only applied once" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          output.decorated = true
          style = ACON::Style::Athena.new input, output
          style.print "<question>do you want <comment>something</>"
          style.puts "?</>"

          ACON::Command::Status::SUCCESS
        end),
        "style/closing_tag.txt",
      },
      # TODO: Enable this test case when multi width char support is added.
      #   "Emojis don't make the line longer than expected" => {
      #     (ACON::Commands::Generic::Proc.new do |input, output|
      #       style = ACON::Style::Athena.new input, output
      #       style.success "Lorem ipsum dolor sit amet"
      #       style.success "Lorem ipsum dolor sit amet with one emoji 🎉"
      #       style.success "Lorem ipsum dolor sit amet with so many of them 👩‍🌾👩‍🌾👩‍🌾👩‍🌾👩‍🌾"

      #       ACON::Command::Status::SUCCESS
      #     end),
      #     "style/emojis.txt",
      #   },
      "Nested tags have no effect on color of the '//' prefix" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          output.decorated = true

          ACON::Style::Athena.new(input, output).block(
            "Árvíztűrőtükörfúrógép Lorem ipsum dolor sit <comment>amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</comment> Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum",
            type: "★",
            prefix: "<fg=default;bg=default> ║ </>",
            escape: false
          )

          ACON::Command::Status::SUCCESS
        end),
        "style/nested_tag_prefix.txt",
      },
      "Do not prepend empty line if the buffer is empty" => {
        (ACON::Commands::Generic::Proc.new do |input, output|
          style = ACON::Style::Athena.new input, output
          style.text "Hello"

          ACON::Command::Status::SUCCESS
        end),
        "style/empty_buffer.txt",
      },
    }
  end

  def test_create_table : Nil
    command = ACON::Commands::Generic.new "foo" do |input, output|
      output.decorated = true
      style = ACON::Style::Athena.new input, output

      style
        .create_table
        .headers(["Foo", "Bar"])
        .rows([["Biz", "Baz"], [12, false]])
        .render

      style.new_line

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::CommandTester.new command

    tester.execute interactive: false, decorated: false
    self.assert_file_equals_string "style/table.txt", tester.display true
  end

  def test_table : Nil
    command = ACON::Commands::Generic.new "foo" do |input, output|
      output.decorated = true
      style = ACON::Style::Athena.new input, output

      style.table ["Foo", "Bar"], [["Biz", "Baz"], [12, false]]

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::CommandTester.new command

    tester.execute interactive: false, decorated: false
    self.assert_file_equals_string "style/table.txt", tester.display true
  end

  def test_horizontal_table : Nil
    command = ACON::Commands::Generic.new "foo" do |input, output|
      output.decorated = true
      style = ACON::Style::Athena.new input, output

      style.horizontal_table ["Foo", "Bar"], [["Biz", "Baz"], [12, false]]

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::CommandTester.new command

    tester.execute interactive: false, decorated: false
    self.assert_file_equals_string "style/table_horizontal.txt", tester.display true
  end

  def test_vertical_table : Nil
    command = ACON::Commands::Generic.new "foo" do |input, output|
      output.decorated = true
      style = ACON::Style::Athena.new input, output

      style.vertical_table ["Foo", "Bar"], [["Biz", "Baz"], [12, false]]

      ACON::Command::Status::SUCCESS
    end

    tester = ACON::Spec::CommandTester.new command

    tester.execute interactive: false, decorated: false
    self.assert_file_equals_string "style/table_vertical.txt", tester.display true
  end
end
