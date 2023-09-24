require "./output"

# Default implementation of `ACON::Style::Interface` that provides a slew of helpful methods for formatting output.
#
# Uses `ACON::Helper::AthenaQuestion` to improve the appearance of questions.
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   style = ACON::Style::Athena.new input, output
#
#   style.title "Some Fancy Title"
#
#   # ...
#
#   ACON::Command::Status::SUCCESS
# end
# ```
class Athena::Console::Style::Athena < Athena::Console::Style::Output
  private MAX_LINE_LENGTH = 120

  protected getter question_helper : ACON::Helper::Question { ACON::Helper::AthenaQuestion.new }

  @input : ACON::Input::Interface
  @buffered_output : ACON::Output::SizedBuffer

  @line_length : Int32
  @progress_bar : ACON::Helper::ProgressBar? = nil

  def initialize(@input : ACON::Input::Interface, output : ACON::Output::Interface)
    width = ACON::Terminal.new.width || MAX_LINE_LENGTH

    @buffered_output = ACON::Output::SizedBuffer.new {{flag?(:windows) ? 4 : 2}}, output.verbosity, false, output.formatter.dup
    @line_length = Math.min(width - {{flag?(:windows) ? 1 : 0}}, MAX_LINE_LENGTH)

    super output
  end

  # :inherit:
  def ask(question : String, default : _)
    self.ask ACON::Question.new question, default
  end

  # :ditto:
  def ask(question : ACON::Question::Base)
    if @input.interactive?
      self.auto_prepend_block
    end

    answer = self.question_helper.ask @input, self, question

    if @input.interactive?
      self.new_line
      @buffered_output.print "\n"
    end

    answer
  end

  # :inherit:
  def ask_hidden(question : String)
    question = ACON::Question(String?).new question, nil

    question.hidden = true

    self.ask question
  end

  # Helper method for outputting blocks of *messages* that powers the `#caution`, `#success`, `#note`, etc. methods.
  # It includes various optional parameters that can be used to print customized blocks.
  #
  # If *type* is provided, its value will be printed within `[]`. E.g. `[TYPE]`.
  #
  # If *style* is provided, each of the *messages* will be printed in that style.
  #
  # *prefix* represents what each of the *messages* should be prefixed with.
  #
  # If *padding* is `true`, empty lines will be added before/after the block.
  #
  # If *escape* is `true`, each of the *messages* will be escaped via `ACON::Formatter::Output.escape`.
  def block(messages : String | Enumerable(String), type : String? = nil, style : String? = nil, prefix : String = " ", padding : Bool = false, escape : Bool = true) : Nil
    messages = messages.is_a?(Enumerable(String)) ? messages : {messages}

    self.auto_prepend_block
    self.puts self.create_block(messages, type, style, prefix, padding, escape)
    self.new_line
  end

  # :inherit:
  #
  # ```text
  # !
  # ! [CAUTION] Some Message
  # !
  # ```
  #
  # White text on a 3 line red background block with an empty line above/below the block.
  def caution(messages : String | Enumerable(String)) : Nil
    self.block messages, "CAUTION", "fg=white;bg=red", " ! ", true
  end

  # :inherit:
  #
  # ```text
  # ----- -------
  #  Foo   Bar
  # ----- -------
  #  Biz   Baz
  #  12    false
  # ----- -------
  #
  # ```
  def table(headers : Enumerable, rows : Enumerable) : Nil
    self.create_table
      .headers(headers)
      .rows(rows)
      .render

    self.new_line
  end

  # Sames as `#table`, but horizontal
  def horizontal_table(headers : Enumerable, rows : Enumerable) : Nil
    self.create_table
      .headers(headers)
      .rows(rows)
      .horizontal
      .render

    self.new_line
  end

  # Sames as `#table`, but vertical
  def vertical_table(headers : Enumerable, rows : Enumerable) : Nil
    self.create_table
      .headers(headers)
      .rows(rows)
      .vertical
      .render

    self.new_line
  end

  # Formats a list of key/value pairs horizontally.
  #
  # TODO: `Mappable` when/if https://github.com/crystal-lang/crystal/issues/10886 is implemented.
  def definition_list(*rows : String | ACON::Helper::Table::Separator | Enumerable({K, V})) : Nil forall K, V
    table_headers = [] of String | ACON::Helper::Table::Cell
    table_row = [] of String | ACON::Helper::Table::Cell | Nil

    rows.each do |row|
      case row
      in String
        table_headers << ACON::Helper::Table::Cell.new row, colspan: 2
        table_row << nil
      in ACON::Helper::Table::Cell
        table_headers << row
        table_row << row
      in Enumerable
        table_headers << row.first_key.to_s
        table_row << row.first_value.to_s
      end
    end

    self.horizontal_table table_headers, {table_row}
  end

  # Creates and returns an Athena styled `ACON::Helper::Table` instance.
  def create_table : ACON::Helper::Table
    style = ACON::Helper::Table.style_definition("suggested").clone
    style.cell_header_format "<info>%s</info>"

    ACON::Helper::Table.new(
      (output = @output).is_a?(ACON::Output::ConsoleOutputInterface) ? output.section : @output
    )
      .style(style)
  end

  # :inherit:
  def choice(question : String, choices : Indexable | Hash, default = nil)
    self.ask ACON::Question::Choice.new question, choices, default
  end

  # :inherit:
  #
  # ```text
  # // Some Message
  # ```
  #
  # White text with one empty line above/below the message(s).
  def comment(messages : String | Enumerable(String)) : Nil
    self.block messages, prefix: "<fg=default;bg=default> // </>", escape: false
  end

  # :inherit:
  def confirm(question : String, default : Bool = true) : Bool
    self.ask ACON::Question::Confirmation.new question, default
  end

  # :inherit:
  #
  # ```text
  # [ERROR] Some Message
  # ```
  #
  # White text on a 3 line red background block with an empty line above/below the block.
  def error(messages : String | Enumerable(String)) : Nil
    self.block messages, "ERROR", "fg=white;bg=red", padding: true
  end

  # Returns a new instance of `self` that outputs to the error output.
  def error_style : self
    self.class.new @input, self.error_output
  end

  # :inherit:
  #
  # ```text
  # [INFO] Some Message
  # ```
  #
  # Green text with two empty lines above/below the message(s).
  def info(messages : String | Enumerable(String)) : Nil
    self.block messages, "INFO", "fg=green", padding: true
  end

  # :inherit:
  #
  # ```text
  # * Item 1
  # * Item 2
  # * Item 3
  # ```
  #
  # White text with one empty line above/below the list.
  def listing(elements : Enumerable) : Nil
    self.auto_prepend_text
    elements.each do |element|
      self.puts " * #{element}"
    end
    self.new_line
  end

  # :ditto:
  def listing(*elements : String) : Nil
    self.listing elements
  end

  # :inherit:
  def new_line(count : Int32 = 1) : Nil
    super
    @buffered_output.print "\n" * count
  end

  # :inherit:
  #
  # ```text
  # ! [NOTE] Some Message
  # ```
  #
  # Green text with one empty line above/below the message(s).
  def note(messages : String | Enumerable(String)) : Nil
    self.block messages, "NOTE", "fg=yellow", " ! "
  end

  # :inherit:
  def puts(messages : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    messages = messages.is_a?(String) ? {messages} : messages

    messages.each do |message|
      super message, verbosity, output_type
      self.write_buffer message, true, verbosity, output_type
    end
  end

  # :inherit:
  def print(messages : String | Enumerable(String), verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    messages = messages.is_a?(String) ? {messages} : messages

    messages.each do |message|
      super message, verbosity, output_type
      self.write_buffer message, false, verbosity, output_type
    end
  end

  # :inherit:
  #
  # ```text
  # Some Message
  # ------------
  # ```
  #
  # Orange text with one empty line above/below the section.
  def section(message : String) : Nil
    self.auto_prepend_block
    self.puts "<comment>#{ACON::Formatter::Output.escape_trailing_backslash message}</>"
    self.puts %(<comment>#{"-" * ACON::Helper.width(ACON::Helper.remove_decoration(self.formatter, message))}</>)
    self.new_line
  end

  # :inherit:
  #
  # ```text
  #  [OK] Some Message
  # ```
  #
  # Black text on a 3 line green background block with an empty line above/below the block.
  def success(messages : String | Enumerable(String)) : Nil
    self.block messages, "OK", "fg=black;bg=green", padding: true
  end

  # def table(headers : Enumerable, rows : Enumerable(Enumerable)) : Nil
  # end

  # :inherit:
  #
  # Same as `#puts` but indented one space and an empty line above the message(s).
  def text(messages : String | Enumerable(String)) : Nil
    self.auto_prepend_text

    messages = messages.is_a?(Enumerable(String)) ? messages : {messages}

    messages.each do |message|
      self.puts " #{message}"
    end
  end

  # :inherit:
  #
  # ```text
  # Some Message
  # ============
  # ```
  #
  # Orange text with one empty line above/below the title.
  def title(message : String) : Nil
    self.auto_prepend_block
    self.puts "<comment>#{ACON::Formatter::Output.escape_trailing_backslash message}</>"
    self.puts %(<comment>#{"=" * ACON::Helper.width(ACON::Helper.remove_decoration(self.formatter, message))}</>)
    self.new_line
  end

  # :inherit:
  #
  # ```text
  #  [WARNING] Some Message
  # ```
  #
  # Black text on a 3 line orange background block with an empty line above/below the block.
  def warning(messages : String | Enumerable(String)) : Nil
    self.block messages, "WARNING", "fg=black;bg=yellow", padding: true
  end

  # :inherit:
  def progress_start(max : Int32? = nil) : Nil
    @progress_bar = self.create_progress_bar max
    self.progress_bar.start
  end

  # :inherit:
  def progress_advance(by step : Int32 = 1) : Nil
    self.progress_bar.advance step
  end

  # :inherit:
  def progress_finish : Nil
    self.progress_bar.finish
    self.new_line 2
    @progress_bar = nil
  end

  def create_progress_bar(max : Int32? = nil) : ACON::Helper::ProgressBar
    bar = super(max)

    {% if !flag?(:windows) || env("TERM_PROGRAM") == "Hyper" %}
      bar.empty_bar_character = "░" # light shade character \u2591
      bar.progress_character = ""
      bar.bar_character = "▓" # dark shade character \u2593
    {% end %}

    bar
  end

  def progress_iterate(enumerable : Enumerable(T), max : Int32? = nil, & : T -> Nil) : Nil forall T
    self.create_progress_bar.iterate(enumerable) do |value|
      yield value
    end

    self.new_line 2
  end

  private def auto_prepend_block : Nil
    chars = @buffered_output.fetch

    if chars.empty?
      return self.new_line
    end

    self.new_line 2 - chars.count '\n'
  end

  private def auto_prepend_text : Nil
    fetched = @buffered_output.fetch

    if !fetched.empty? && !fetched.ends_with? "\n"
      self.new_line
    end
  end

  private def create_block(messages : Enumerable(String), type : String? = nil, style : String? = nil, prefix : String = " ", padding : Bool = false, escape : Bool = true) : Array(String)
    indent_length = 0
    prefix_length = ACON::Helper.width ACON::Helper.remove_decoration self.formatter, prefix
    lines = [] of String

    unless type.nil?
      type = "[#{type}] "
      indent_length = ACON::Helper.width type
      line_indentation = " " * indent_length
    end

    output_wrapper = ACON::Helper::OutputWrapper.new

    messages.each_with_index do |message, idx|
      message = ACON::Formatter::Output.escape message if escape

      lines.concat output_wrapper.wrap(message, @line_length - prefix_length - indent_length, ACON::System::EOL).split ACON::System::EOL

      lines << "" if messages.size > 1 && idx < (messages.size - 1)
    end

    first_line_index = 0
    if padding && self.decorated?
      first_line_index = 1
      lines.unshift ""
      lines << ""
    end

    lines.map_with_index do |line, idx|
      unless type.nil?
        line = first_line_index == idx ? "#{type}#{line}" : "#{line_indentation}#{line}"
      end

      line = "#{prefix}#{line}"
      line += " " * Math.max @line_length - ACON::Helper.width(ACON::Helper.remove_decoration(self.formatter, line)), 0

      if style
        line = "<#{style}>#{line}</>"
      end

      line
    end
  end

  private def write_buffer(message : String | Enumerable(String), new_line : Bool, verbosity : ACON::Output::Verbosity = :normal, output_type : ACON::Output::Type = :normal) : Nil
    @buffered_output.write message, new_line, verbosity, output_type
  end

  private def progress_bar : ACON::Helper::ProgressBar
    @progress_bar || raise ACON::Exceptions::RuntimeError.new "The ProgressBar is not started."
  end
end
