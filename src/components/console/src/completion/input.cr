abstract class Athena::Console::Input; end

require "../input/argv"

class Athena::Console::Completion::Input < Athena::Console::Input::ARGV
  enum Type
    ARGUMENT_VALUE
    OPTION_VALUE
    ARGUMENT_NAME
  end

  def self.from_string(input : String, current_index : Int32) : self
    tokens = input.match!(/(?<=^|\s)(['"]?)(.+?)(?<!\\\\)\1(?=$|\s)/)

    self.from_tokens tokens[0], current_index
  end

  def self.from_tokens(tokens : Array(String), current_index : Int32) : self
    new tokens, current_index
  end

  getter completion_type : ACON::Completion::Input::Type? = nil
  getter completion_name : String? = nil
  getter completion_value : String = ""

  @current_index : Int32 = 1

  def initialize(tokens : Array(String), @current_index : Int32)
    super tokens
    @tokens = tokens
  end

  def must_suggest_values_for?(option_name : String) : Bool
    @completion_type.option_value? && option_name == @completion_name
  end
end
