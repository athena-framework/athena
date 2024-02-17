require "../spec_helper"

abstract struct AbstractQuestionHelperTest < ASPEC::TestCase
  def initialize
    @helper_set = ACON::Helper::HelperSet.new ACON::Helper::Formatter.new

    @output = ACON::Output::IO.new IO::Memory.new
  end

  protected def with_input(data : String, interactive : Bool = true, & : ACON::Input::Interface -> Nil) : Nil
    input_stream = IO::Memory.new data
    input = ACON::Input::Hash.new
    input.stream = input_stream
    input.interactive = interactive

    yield input
  end

  protected def assert_output_contains(string : String, normalize : Bool = false) : Nil
    stream = @output.io
    stream.rewind

    output = stream.to_s

    if normalize
      output = output.gsub EOL, "\n"
    end

    output.should contain string
  end
end
