require "../spec_helper"

struct ConsoleSectionOutputTest < ASPEC::TestCase
  @io : IO::Memory

  def initialize
    @io = IO::Memory.new
  end

  def test_adding_multiple_sections : Nil
    sections = Array(ACON::Output::Section).new
    ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    sections.size.should eq 2
  end

  def test_clear_all : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo#{EOL}Bar"
    output.clear

    @io.to_s.should eq "Foo#{EOL}Bar#{EOL}\e[2A\e[0J"
  end

  def test_clear_number_of_lines : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo\nBar\nBaz\nFooBar"
    output.clear 2

    @io.to_s.should eq "Foo\nBar\nBaz\nFooBar#{EOL}\e[2A\e[0J"
  end

  def test_clear_number_more_than_current_size : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo"
    output.clear 2

    @io.to_s.should eq "Foo#{EOL}\e[2A\e[0J"
  end

  def test_clear_number_of_lines_multiple_sections : Nil
    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output2.puts "Foo"
    output2.puts "Bar"
    output2.clear 1
    output1.puts "Baz"

    @io.to_s.should eq "Foo#{EOL}Bar#{EOL}\e[1A\e[0J\e[1A\e[0JBaz#{EOL}Foo#{EOL}"
  end

  def test_clear_number_of_lines_multiple_sections_preserves_empty_lines : Nil
    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output2.puts "#{EOL}foo"
    output2.clear 1
    output1.puts "bar"

    @io.to_s.should eq "#{EOL}foo#{EOL}\e[1A\e[0J\e[1A\e[0Jbar#{EOL}#{EOL}"
  end

  def test_clear_with_question : Nil
    input = ACON::Input::Hash.new
    input.stream = IO::Memory.new "Batman & Robin\n"
    input.interactive = true

    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    ACON::Helper::Question.new.ask input, output, ACON::Question(String?).new("What's your favorite superhero?", nil)
    output.clear

    @io.to_s.should eq "What's your favorite superhero?#{EOL}\e[2A\e[0J"
  end

  def test_clear_after_overwrite_clear_correct_number_of_lines : Nil
    expected = IO::Memory.new

    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.overwrite "foo"
    expected << "foo" << EOL

    output.clear
    expected << "\e[1A\e[0J"

    @io.to_s.should eq expected.to_s
  end

  def test_overwrite : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo"
    output.overwrite "Bar"

    @io.to_s.should eq "Foo#{EOL}\e[1A\e[0JBar#{EOL}"
  end

  def test_overwrite_multiple_lines : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo#{EOL}Bar#{EOL}Baz"
    output.overwrite "Bar"

    @io.to_s.should eq "Foo#{EOL}Bar#{EOL}Baz#{EOL}\e[3A\e[0JBar#{EOL}"
  end

  def test_overwrite_multiple_section_output : Nil
    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output1.puts "Foo"
    output2.puts "Bar"

    output1.overwrite "Baz"
    output2.overwrite "Foobar"

    @io.to_s.should eq "Foo#{EOL}Bar#{EOL}\e[2A\e[0JBar#{EOL}\e[1A\e[0JBaz#{EOL}Bar#{EOL}\e[1A\e[0JFoobar#{EOL}"
  end

  def test_max_height : Nil
    expected = IO::Memory.new

    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output.max_height = 3

    # Fill the section
    output.puts({"One", "Two", "Three"})
    expected << "One" << EOL << "Two" << EOL << "Three" << EOL

    # Cause overflow that'll redraw whole section, without the first line
    output.puts "Four"
    expected << "\e[3A\e[0J"
    expected << "Two" << EOL << "Three" << EOL << "Four" << EOL

    # Cause overflow with multiple new lines at once
    output.puts "Five#{EOL}Six"
    expected << "\e[3A\e[0J"
    expected << "Four" << EOL << "Five" << EOL << "Six" << EOL

    # Reset line height that'll redraw whole section, displaying all lines
    output.max_height = nil
    expected << "\e[3A\e[0J"
    expected << "One" << EOL << "Two" << EOL << "Three" << EOL
    expected << "Four" << EOL << "Five" << EOL << "Six" << EOL

    @io.to_s.should eq expected.to_s
  end

  def test_max_height_multiple_sections : Nil
    expected = IO::Memory.new

    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output1.max_height = 3

    output2 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output2.max_height = 3

    # Fill the first section
    output1.puts({"One", "Two", "Three"})
    expected << "One" << EOL << "Two" << EOL << "Three" << EOL

    # Fill the second section
    output2.puts({"One", "Two", "Three"})
    expected << "One" << EOL << "Two" << EOL << "Three" << EOL

    # Cause overflow on second section that'll redraw whole section, without the first line
    output2.puts "Four"
    expected << "\e[3A\e[0J"
    expected << "Two" << EOL << "Three" << EOL << "Four" << EOL

    # Cause overflow on first section that'll redraw whole section, without the first line
    output1.puts "Four#{EOL}Five#{EOL}Six"
    expected << "\e[6A\e[0J"
    expected << "Four" << EOL << "Five" << EOL << "Six" << EOL
    expected << "Two" << EOL << "Three" << EOL << "Four" << EOL

    @io.to_s.should eq expected.to_s
  end

  def test_max_height_without_new_line : Nil
    expected = IO::Memory.new

    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output.max_height = 3

    # Fill the section
    output.puts({"One", "Two"})
    output.print "Three"
    expected << "One" << EOL << "Two" << EOL << "Three" << EOL

    # Append text to the last line
    output.print " and Four"
    expected << "\e[1A\e[0J" << "Three and Four" << EOL

    @io.to_s.should eq expected.to_s
  end

  def test_write_without_new_line : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.print "Foo#{EOL}"
    output.print "Bar"

    @io.to_s.should eq "Foo#{EOL}Bar#{EOL}"
  end

  def test_write_multiple_sections_output_without_new_lines : Nil
    expected = IO::Memory.new

    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output1.print "Foo"
    expected << "Foo" << EOL

    output2.puts "Bar"
    expected << "Bar" << EOL

    output1.puts " is not foo."
    expected << "\e[2A\e[0JFoo is not foo." << EOL << "Bar" << EOL

    output2.print "Baz"
    expected << "Baz" << EOL

    output2.print "bar"
    expected << "\e[1A\e[0JBazbar" << EOL

    output2.puts ""
    expected << "\e[1A\e[0JBazbar" << EOL

    output2.puts ""
    expected << EOL

    output2.puts "Done."
    expected << "Done." << EOL

    @io.to_s.should eq expected.to_s
  end
end
