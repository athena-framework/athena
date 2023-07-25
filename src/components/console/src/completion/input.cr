abstract class Athena::Console::Input; end

require "../input/argv"

# A specialization of `ACON::Input::ARGV` that allows for unfinished name/values.
# Exposes information about the name, type, and value of the value/name being completed.
class Athena::Console::Completion::Input < Athena::Console::Input::ARGV
  enum Type
    # Nothing should be completed.
    NONE

    # Completing the value of an argument.
    ARGUMENT_VALUE

    # Completing the value of an option.
    OPTION_VALUE

    # Completing the name of an option.
    OPTION_NAME
  end

  def self.from_string(input : String, current_index : Int32) : self
    tokens = input.scan(/(?<=^|\s)(['"]?)(.+?)(?<!\\\\)\1(?=$|\s)/).map &.[0]

    self.from_tokens tokens, current_index
  end

  def self.from_tokens(tokens : Array(String), current_index : Int32) : self
    input = new tokens
    input.current_index = current_index
    input.tokens = tokens

    input
  end

  # Returns which [type][ACON::Completion::Input::Type] of completion is required.
  getter completion_type : ACON::Completion::Input::Type = :none

  # Returns the name of the argument/option when completing a value.
  getter completion_name : String? = nil

  # Returns the value typed by the user, or empty string.
  getter completion_value : String = ""

  protected setter current_index : Int32 = 1
  protected setter tokens : Array(String)

  # :inherit:
  #
  # ameba:disable Metrics/CyclomaticComplexity
  def bind(definition : ACON::Input::Definition) : Nil
    super definition

    relevant_token = self.relevant_token

    if '-' == relevant_token[0]?
      split_token = relevant_token.split('=', 2)
      option_token, option_value = (split_token[0]? || ""), (split_token[1]? || "")

      option = self.option_from_token option_token

      if option.nil? && !self.free_cursor?
        @completion_type = :option_name
        @completion_value = relevant_token

        return
      end

      if option && option.accepts_value?
        @completion_type = :option_value
        @completion_name = option.name
        @completion_value = option_value.presence || (!option_token.starts_with?("--") ? option_token[2..] : "")

        return
      end
    end

    previous_token = @tokens[@current_index - 1]? || ""

    if '-' == previous_token[0]? && !previous_token.strip("-").empty?
      # Did the previous option accept a value?
      previous_option = self.option_from_token previous_token

      if previous_option && previous_option.accepts_value?
        @completion_type = :option_value
        @completion_name = previous_option.name
        @completion_value = relevant_token

        return
      end
    end

    # Complete argument value
    @completion_type = :argument_value

    argument_name = nil
    @definition.arguments.each do |arg_name, _|
      argument_name = arg_name

      break unless @arguments.has_key? arg_name

      argument_value = @arguments[arg_name]
      @completion_name = arg_name

      if argument_value.is_a? Array
        @completion_value = argument_value.empty? ? "" : argument_value.last.to_s
      else
        @completion_value = argument_value.to_s
      end
    end

    if @current_index >= @tokens.size
      if argument_name && (!@arguments.has_key?(argument_name) || @definition.argument(argument_name).is_array?)
        @completion_name = argument_name
        @completion_value = ""
      else
        # Reached end of data
        @completion_type = :none
        @completion_name = nil
        @completion_value = ""
      end
    end
  end

  # Returns `true` if this input is able to suggest values for the provided *option_name*.
  def must_suggest_values_for?(option_name : String) : Bool
    @completion_type.option_value? && option_name == @completion_name
  end

  # Returns `true` if this input is able to suggest values for the provided *argument_name*.
  def must_suggest_argument_values_for?(argument_name : String) : Bool
    @completion_type.argument_value? && argument_name == @completion_name
  end

  # Returns the current token of the cursor, or last token if the cursor is at the end of the input.
  def relevant_token : String
    @tokens[self.free_cursor? ? @current_index - 1 : @current_index]? || ""
  end

  # :nodoc:
  def to_s(io : IO) : Nil
    i = 0
    @tokens.each_with_index do |token, idx|
      io << token
      io << '|' if idx == @current_index
      io << ' ' unless @tokens.size == (idx + 1)
      i = idx
    end

    if @current_index > i
      io << '|'
    end
  end

  protected def parse_token(token : String, parse_options : Bool) : Bool
    begin
      return super
    rescue ex : ACON::Exceptions::InvalidArgument
      # noop, completed input is almost never valid
    end

    parse_options
  end

  private def option_from_token(option_token : String) : ACON::Input::Option?
    option_name = option_token.lstrip '-'

    return nil if option_name.empty?

    if '-' == (option_token[1]? || " ")
      # Long option name
      return @definition.options[option_name]?
    end

    # Short option name
    @definition.has_shortcut?(option_name[0]) ? @definition.option_for_shortcut(option_name[0]) : nil
  end

  private def free_cursor? : Bool
    number_of_tokens = @tokens.size

    if @current_index > number_of_tokens
      raise "Current index is invalid, it must be the number of input tokens."
    end

    @current_index >= number_of_tokens
  end
end
