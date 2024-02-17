# Provides a method to ask the user for more information;
# such as to confirm an action, or to provide additional values.
#
# See `ACON::Question` namespace for more information.
class Athena::Console::Helper::Question < Athena::Console::Helper
  @@stty : Bool = true

  def self.disable_stty : Nil
    @@stty = false
  end

  @stream : IO? = nil

  def ask(input : ACON::Input::Interface, output : ACON::Output::Interface, question : ACON::Question::Base)
    if output.is_a? ACON::Output::ConsoleOutputInterface
      output = output.error_output
    end

    return self.default_answer question unless input.interactive?

    if input.is_a?(ACON::Input::Streamable) && (stream = input.stream)
      @stream = stream
    end

    begin
      if question.validator.nil?
        return self.do_ask output, question
      end

      self.validate_attempts(output, question) do
        self.do_ask output, question
      end
    rescue ex : ACON::Exceptions::MissingInput
      input.interactive = false

      raise ex
    end
  end

  protected def format_choice_question_choices(question : ACON::Question::AbstractChoice, tag : String) : Array(String)
    messages = Array(String).new

    choices = question.choices

    max_width = choices.keys.max_of { |k| k.is_a?(String) ? self.class.width(k) : k.digits.size }

    choices.each do |k, v|
      padding = " " * (max_width - (k.is_a?(String) ? k.size : k.digits.size))

      messages << "  [<#{tag}>#{k}#{padding}</#{tag}>] #{v}"
    end

    messages
  end

  protected def write_error(output : ACON::Output::Interface, error : Exception) : Nil
    message = if (helper_set = self.helper_set) && (formatter_helper = helper_set[ACON::Helper::Formatter]?)
                formatter_helper.format_block error.message || "", "error"
              else
                "<error>#{error.message}</error>"
              end

    output.puts message
  end

  protected def write_prompt(output : ACON::Output::Interface, question : ACON::Question::Base) : Nil
    message = question.question

    if question.is_a? ACON::Question::AbstractChoice
      output.puts question.question
      output.puts self.format_choice_question_choices question, "info"

      message = question.prompt
    end

    output.print message
  end

  private def default_answer(question : ACON::Question::Base)
    default = question.default

    return default if default.nil?

    if validator = question.validator
      return validator.call default
    elsif question.is_a? ACON::Question::AbstractChoice
      choices = question.choices

      unless question.is_a? ACON::Question::MultipleChoice
        return choices[default]? || default
      end

      default = case default
                when String then default.split(',').map! do |item|
                  if idx = item.to_i?
                    item = idx
                  end

                  choices[item]? || item.to_s
                end
                else
                  default
                end
    end

    default
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def do_ask(output : ACON::Output::Interface, question : ACON::Question::Base)
    self.write_prompt output, question

    input_stream = @stream || STDIN
    autocompleter = question.autocompleter_callback

    # TODO: Handle invalid input IO

    if autocompleter.nil? || !@@stty || !ACON::Terminal.has_stty_available?
      response = nil

      if question.hidden?
        begin
          hidden_response = self.hidden_response output, input_stream
          response = question.trimmable? ? hidden_response.strip : hidden_response
        rescue ex : ACON::Exceptions::ConsoleException
          raise ex unless question.hidden_fallback?
        end
      end

      if response.nil?
        raise ACON::Exceptions::MissingInput.new "Aborted." unless response = self.read_input input_stream, question
        response = response.strip if question.trimmable?
      end
    else
      autocomplete = self.autocomplete output, question, input_stream, autocompleter
      response = question.trimmable? ? autocomplete.strip : autocomplete
    end

    if output.is_a? ACON::Output::Section
      output.add_content "" # add EOL to the question
      output.add_content response
    end

    question.process_response response
  end

  private def autocomplete(output : ACON::Output::Interface, question : ACON::Question::Base, input_stream : IO, autocompleter) : String
    # TODO: Support autocompletion.
    self.read_input(input_stream, question) || raise ACON::Exceptions::MissingInput.new "Aborted."
  end

  private def hidden_response(output : ACON::Output::Interface, input_stream : IO) : String
    response = if input_stream.tty? && input_stream.responds_to? :noecho
                 input_stream.noecho &.gets 4096
               elsif @@stty && ACON::Terminal.has_stty_available?
                 stty_mode = `stty -g`
                 system "stty -echo"

                 input_stream.gets(4096).tap { system "stty #{stty_mode}" }
               elsif input_stream.tty?
                 raise ACON::Exceptions::RuntimeError.new "Unable to hide the response."
               end

    raise ACON::Exceptions::MissingInput.new "Aborted." if response.nil?

    output.puts ""

    response
  end

  private def read_input(input_stream : IO, question : ACON::Question::Base) : String?
    unless question.multi_line?
      return input_stream.gets 4096
    end

    # Can't just do `.gets_to_end` because we need to be able
    # to return early if the only input provided is a newline.
    String.build do |io|
      input_stream.each_char do |char|
        break if '\n' == char && io.empty?
        io << char
      end
    end
  end

  private def validate_attempts(output : ACON::Output::Interface, question : ACON::Question::Base, &)
    error = nil
    attempts = question.max_attempts

    while attempts.nil? || attempts > 0
      self.write_error output, error if error

      begin
        return question.validator.not_nil!.call yield
      rescue ex : ACON::Exceptions::RuntimeError
        raise ex
      rescue ex : Exception
        error = ex
      ensure
        attempts -= 1 if attempts
        sleep 0
      end
    end

    raise error.not_nil!
  end
end
