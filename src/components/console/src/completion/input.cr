abstract class Athena::Console::Input; end

require "../input/argv"

class Athena::Console::Completion::Input < Athena::Console::Input::ARGV
  enum Type
    NONE
    ARGUMENT_VALUE
    OPTION_VALUE
    OPTION_NAME
  end

  def self.from_string(input : String, current_index : Int32) : self
    tokens = input.match!(/(?<=^|\s)(['"]?)(.+?)(?<!\\\\)\1(?=$|\s)/)

    self.from_tokens tokens[0], current_index
  end

  def self.from_tokens(tokens : Array(String), current_index : Int32) : self
    new tokens, current_index
  end

  getter completion_type : ACON::Completion::Input::Type = :none
  getter completion_name : String? = nil
  getter completion_value : String = ""

  @current_index : Int32 = 1

  def initialize(tokens : Array(String), @current_index : Int32)
    super tokens
    @tokens = tokens
  end

  def bind(definition : ACON::Input::Definition) : Nil
    super definition

    relevant_token = self.relevant_token

    if '-' == relevant_token[0]?
      split_token = relevant_token.split('=', 2)
      option_token, option_value = (split_token[0]? || ""), (split_token[1]? || "")

      option = self.option_from_token option_token

      if option.nil? && !self.is_cursor_free?
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
    @definition.arguments.each do |arg_name, argument|
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

  def must_suggest_values_for?(option_name : String) : Bool
    @completion_type.option_value? && option_name == @completion_name
  end

  # The token of the cursor, or last token if the cursor is at the end of the input
  def relevant_token : String
    @tokens[self.is_cursor_free? ? @current_index - 1 : @current_index]? || ""
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

  private def is_cursor_free? : Bool
    number_of_tokens = @tokens.size

    if @current_index > number_of_tokens
      raise ACON::Exceptions::Logic.new "Current index is invalid, it must be the number of input tokens or one more."
    end

    @current_index >= number_of_tokens
  end
end
