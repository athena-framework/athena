require "../spec_helper"

struct ConsoleSectionOutputTest < ASPEC::TestCase
  @io : IO::Memory

  def initialize
    @io = IO::Memory.new
  end

  def test_clear_all : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo\nBar"
    output.clear

    output.io.to_s.should eq "Foo\nBar\n\e[2A\e[0J"
  end

  def test_clear_number_of_lines : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo\nBar\nBaz\nFooBar"
    output.clear 2

    output.io.to_s.should eq "Foo\nBar\nBaz\nFooBar\n\e[2A\e[0J"
  end

  def test_clear_number_more_than_current_size : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo"
    output.clear 2

    output.io.to_s.should eq "Foo\n\e[1A\e[0J"
  end

  def test_clear_number_of_lines_multiple_sections : Nil
    output = ACON::Output::IO.new @io

    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new

    output2.puts "Foo"
    output2.puts "Bar"
    output2.clear 1
    output1.puts "Baz"

    output.io.to_s.should eq "Foo\nBar\n\e[1A\e[0J\e[1A\e[0JBaz\nFoo\n"
  end

  def test_clear_number_of_lines_multiple_sections_preserves_empty_lines : Nil
    output = ACON::Output::IO.new @io

    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new

    output2.puts "\nfoo"
    output2.clear 1
    output1.puts "bar"

    output.io.to_s.should eq "\nfoo\n\e[1A\e[0J\e[1A\e[0Jbar\n\n"
  end

  def test_overwrite : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo"
    output.overwrite "Bar"

    output.io.to_s.should eq "Foo\n\e[1A\e[0JBar\n"
  end

  def test_overwrite_multiple_lines : Nil
    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    output.puts "Foo\nBar\nBaz"
    output.overwrite "Bar"

    output.io.to_s.should eq "Foo\nBar\nBaz\n\e[3A\e[0JBar\n"
  end

  def test_multiple_section_output : Nil
    output = ACON::Output::IO.new @io

    sections = Array(ACON::Output::Section).new
    output1 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new output.io, sections, :normal, true, ACON::Formatter::Output.new

    output1.puts "Foo"
    output2.puts "Bar"

    output1.overwrite "Baz"
    output2.overwrite "Foobar"

    output.io.to_s.should eq "Foo\nBar\n\e[2A\e[0JBar\n\e[1A\e[0JBaz\nBar\n\e[1A\e[0JFoobar\n"
  end

  def test_clear_with_question : Nil
    input = ACON::Input::Hash.new
    input.stream = IO::Memory.new "Batman & Robin\n"
    input.interactive = true

    sections = Array(ACON::Output::Section).new
    output = ACON::Output::Section.new @io, sections, :normal, true, ACON::Formatter::Output.new

    ACON::Helper::Question.new.ask input, output, ACON::Question(String?).new("What's your favorite superhero?", nil)
    output.clear

    output.io.to_s.should eq "What's your favorite superhero?\n\e[2A\e[0J"
  end
end
