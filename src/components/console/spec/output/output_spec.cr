require "../spec_helper"

private class MockOutput < ACON::Output
  getter output : String = ""

  def clear : Nil
    @output = ""
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    @output += message
    @output += "\n" if new_line
  end
end

struct OutputTest < ASPEC::TestCase
  def test_write_verbosity_quiet : Nil
    output = MockOutput.new :quiet
    output.puts "foo"
    output.output.should be_empty
  end

  def test_write_array_messages : Nil
    output = MockOutput.new
    output.puts ["foo", "bar"]
    output.output.should eq "foo\nbar\n"
  end

  @[DataProvider("message_provider")]
  def test_write_raw_message(message : String, output_type : ACON::Output::Type, expected : String) : Nil
    output = MockOutput.new
    output.puts message, output_type: output_type
    output.output.should eq expected
  end

  def message_provider : Tuple
    {
      {"<info>foo</info>", ACON::Output::Type::RAW, "<info>foo</info>\n"},
      {"<info>foo</info>", ACON::Output::Type::PLAIN, "foo\n"},
    }
  end

  def test_write_non_decorated : Nil
    output = MockOutput.new
    output.decorated = false
    output.puts "<info>foo</info>"
    output.output.should eq "foo\n"
  end

  def test_write_decorated : Nil
    foo_style = ACON::Formatter::OutputStyle.new :yellow, :red, :blink
    output = MockOutput.new
    output.formatter.set_style "FOO", foo_style
    output.decorated = true
    output.puts "<foo>foo</foo>"
    output.output.should eq "\e[33;41;5mfoo\e[0m\n"
  end

  def test_write_decorated_invalid_style : Nil
    output = MockOutput.new
    output.puts "<bar>foo</bar>"
    output.output.should eq "<bar>foo</bar>\n"
  end

  @[DataProvider("verbosity_provider")]
  def test_write_with_verbosity(verbosity : ACON::Output::Verbosity, expected : String) : Nil
    output = MockOutput.new

    output.verbosity = verbosity
    output.print "1"
    output.print "2", :quiet
    output.print "3", :normal
    output.print "4", :verbose
    output.print "5", :very_verbose
    output.print "6", :debug

    output.output.should eq expected
  end

  def verbosity_provider : Tuple
    {
      {ACON::Output::Verbosity::QUIET, "2"},
      {ACON::Output::Verbosity::NORMAL, "123"},
      {ACON::Output::Verbosity::VERBOSE, "1234"},
      {ACON::Output::Verbosity::VERY_VERBOSE, "12345"},
      {ACON::Output::Verbosity::DEBUG, "123456"},
    }
  end
end
