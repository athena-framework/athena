abstract class Athena::Console::Output; end

require "../output/interface"

class Athena::Console::Helper::ProgressBar
  enum Format
    DEBUG
    VERY_VERBOSE
    VERBOSE
    NORMAL

    DEBUG_NOMAX
    VERBOSE_NOMAX
    VERY_VERBOSE_NOMAX
    NORMAL_NOMAX
  end

  alias PlaceholderFormatter = Proc(Athena::Console::Helper::ProgressBar, Athena::Console::Output::Interface, String)

  # INTERNAL
  protected class_getter formats : Hash(String, String) { self.init_formats }

  # INTERNAL
  protected class_getter placeholder_formatters : Hash(String, PlaceholderFormatter) { self.init_placeholder_formatters }

  def self.set_format_definition(name : String, format : String) : Nil
    self.formats[name] = style
  end

  def self.format_definition(name : String) : String?
    self.formats[name]?
  end

  private def self.init_formats : Hash(String, String)
    {
      "debug"       => " %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%/%estimated:-6s% %memory:6s%",
      "debug_nomax" => " %current% [%bar%] %elapsed:6s% %memory:6s%",

      "very_verbose"       => " %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%/%estimated:-6s%",
      "very_verbose_nomax" => " %current% [%bar%] %elapsed:6s%",

      "verbose"       => " %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%",
      "verbose_nomax" => " %current% [%bar%] %elapsed:6s%",

      "normal"       => " %current%/%max% [%bar%] %percent:3s%%",
      "normal_nomax" => " %current% [%bar%]",
    }
  end

  def self.set_placeholder_formatter(name : String, &block : self, ACON::Output::Interface -> String) : Nil
    self.set_placeholder_formatter name, block
  end

  def self.set_placeholder_formatter(name : String, callable : ACON::Helper::ProgressBar::PlaceholderFormatter) : Nil
    self.placeholder_formatters[name] = callable
  end

  def self.placeholder_formatter(name : String) : ACON::Helper::ProgressBar::PlaceholderFormatter?
    self.placeholder_formatters[name]?
  end

  private def self.init_placeholder_formatters : Hash(String, PlaceholderFormatter)
    {
      "bar" => PlaceholderFormatter.new do |bar, output|
        complete_bars = bar.bar_offset

        display = bar.bar_character * complete_bars

        if complete_bars < bar.bar_width
          empty_bars = bar.bar_width - complete_bars - ACON::Helper.width(ACON::Helper.remove_decoration(output.formatter, bar.progress_character))

          display += bar.progress_character
          display += bar.empty_bar_character * empty_bars
        end

        display
      end,

      "current" => PlaceholderFormatter.new { |bar| bar.progress.to_s.rjust bar.step_width, ' ' },
      "max"     => PlaceholderFormatter.new { |bar| bar.max_steps.to_s },
      "percent" => PlaceholderFormatter.new { |bar| (bar.progress_percent * 100).to_s },
    }
  end

  @output : ACON::Output::Interface
  @terminal : ACON::Terminal
  @start_time = Time::Span
  @cursor : ACON::Cursor

  getter bar_width : Int32 = 28
  property bar_character : String { @max ? "=" : @empty_bar_character }
  property empty_bar_character : String = "-"
  property progress_character : String = ">"

  @overwrite : Bool = false
  @max : Int32? = nil
  getter! step_width : Int32

  @redraw_frequency : Int32? = 1
  @minimum_seconds_between_redraws : Float64 = 0
  @maximum_seconds_between_redraws : Float64 = 1
  @format : String? = nil
  @internal_format : String? = nil
  @step : Int32 = 0
  @starting_step : Int32 = 0
  @percent : Float64 = 0.0
  @last_write_time : Time::Span = Time::Span.zero
  @previous_message : String? = nil
  @write_count : Int32 = 0
  @messages : Hash(String, String) = Hash(String, String).new

  @placeholder_formatters : Hash(String, PlaceholderFormatter) = Hash(String, PlaceholderFormatter).new

  def initialize(output : ACON::Output::Interface, max : Int32 = 0, minimum_seconds_between_redraws : Float64 = 0.04)
    if output.is_a? ACON::Output::ConsoleOutputInterface
      output = output.error_output
    end

    @output = output
    @terminal = ACON::Terminal.new

    if 0 < minimum_seconds_between_redraws
      @redraw_frequency = nil
      @minimum_seconds_between_redraws = minimum_seconds_between_redraws
    end

    unless @output.decorated?
      # Disable overwrite when output does not support ANSI codes.
      @overwrite = false

      # Set a reasonable redraw freq so output isn't flooded
      @redraw_frequency = nil
    end

    @start_time = Time.monotonic
    @cursor = ACON::Cursor.new @output

    self.max_steps = max
  end

  def progress : Int32
    @step
  end

  def max_steps : Int32
    @max.not_nil!
  end

  def progress_percent : Float64
    @percent
  end

  def bar_width=(size : Int32) : Nil
    @bar_width = Math.max 1, size
  end

  def bar_offset : Int32
    if @max
      return (@percent * @bar_width).floor.to_i
    end

    if @redraw_frequency.nil?
      return ((Math.min(5, bar_width / 15) * @write_count) % @bar_width).floor.to_i
    end

    (@step % @bar_width).floor.to_i
  end

  def placeholder_formatter(name : String) : ACON::Helper::ProgressBar::PlaceholderFormatter?
    @placeholder_formatters[name]? || self.class.placeholder_formatter name
  end

  def set_placeholder_formatter(name : String, &block : self, ACON::Output::Interface -> String) : Nil
    self.set_placeholder_formatter name, block
  end

  def set_placeholder_formatter(name : String, callable : ACON::Helper::ProgressBar::PlaceholderFormatter) : Nil
    @placeholder_formatters[name] = callable
  end

  def max_steps=(max : Int32) : Nil
    @format = nil
    @max = Math.max 0, max
    @step_width = self.max_steps.zero? ? ACON::Helper.width(self.max_steps.to_s) : 4
  end

  def start(max : Int32? = nil, start_at : Int32 = 0) : Nil
    @start_time = Time.monotonic
    @step = start_at
    @starting_step = start_at

    if start_at > 0
      self.progress = start_at
    else
      @percent = 0.0
    end

    unless max.nil?
      self.max_steps = max
    end

    self.display
  end

  def advance(step : Int32 = 1) : Nil
    self.progress = @step + step
  end

  def progress=(step : Int32) : Nil
    if (ms = @max) && (step > ms)
      @max = step
    elsif step < 0
      step = 0
    end

    max = self.max_steps

    redraw_frequency = @redraw_frequency || ((max > 0 ? max : 10) / 10)
    previous_period = @step // redraw_frequency
    current_period = step // redraw_frequency
    @step = step

    @percent = max > 0 ? @step / max : 0.0
    time_interval = Time.monotonic - @last_write_time

    # Draw regardless of other limits
    if @max == step
      self.display

      return
    end

    # Throttling
    if time_interval.total_seconds < @minimum_seconds_between_redraws
      return
    end

    # Draw each step period, but not too late
    if previous_period != current_period || time_interval.total_seconds >= @maximum_seconds_between_redraws
      self.display
    end
  end

  def display : Nil
    return if @output.verbosity.quiet?

    if @format.nil?
      self.set_real_format @internal_format || self.determine_base_format.to_s.downcase
    end

    self.overwrite self.build_line
  end

  def finish
  end

  private def overwrite(message : String) : Nil
    return if message == @previous_message

    original_message = message

    if @overwrite
      if previous_message = @previous_message
        case output = @output
        when ACON::Output::Section
          message_lines = previous_message.lines
          line_count = message_lines.size

          message_lines.each do |line|
            message_line_length = ACON::Helper.width ACON::Helper.remove_decoration output.formatter, line

            if message_line_length > @terminal.width
              line_count = (message_line_length / @terminal.width).floor.to_i
            end
          end

          output.clear line_count
        else
          previous_message.count('\n').times do |t|
            @cursor.move_to_column 1
            @cursor.clear_line
            @cursor.move_up
          end
          @cursor.move_to_column 1
          @cursor.clear_line
        end
      end
    elsif @step > 0
      message = "#{ACON::System::EOL}#{message}"
    end

    @previous_message = original_message
    @last_write_time = Time.monotonic

    @output.print message
    @write_count += 1
  end

  private def build_line : String
    format = @format.not_nil!

    regex = /%([a-z\-_]+)(?::([^%]+))?%/i

    callback = Proc(String, Regex::MatchData, String).new do |string, match|
      if formatter = self.placeholder_formatter match[1]
        text = formatter.call self, @output
      elsif message = @messages[match[1]]?
        text = message
      else
        next match[0]
      end

      if format_string = match[2]?
        text = sprintf "%#{format_string}", text
      end

      text
    end

    line = format.gsub regex, &callback

    # Gets string length for each sub-line with multiline format
    lines_length = line.split("\n").map { |sub_line| ACON::Helper.width ACON::Helper.remove_decoration @output.formatter, sub_line.rstrip "\r" }
    lines_width = lines_length.max

    terminal_width = @terminal.width

    if lines_width <= terminal_width
      return line
    end

    self.bar_width = @bar_width - lines_width + terminal_width

    format.gsub regex, &callback
  end

  private def set_real_format(format : String) : Nil
    # Try to use the _NOMAX variant if available
    @format = if @max.nil? && (resolved_format = self.class.format_definition "#{format}_nomax")
                resolved_format
              elsif resolved_format = self.class.format_definition format
                resolved_format
              else
                format
              end
  end

  private def determine_base_format : Format
    case @output.verbosity
    when .debug?        then @max ? Format::DEBUG : Format::DEBUG_NOMAX
    when .very_verbose? then @max ? Format::VERY_VERBOSE : Format::VERY_VERBOSE_NOMAX
    when .verbose?      then @max ? Format::VERBOSE : Format::VERBOSE_NOMAX
    else
      @max ? Format::NORMAL : Format::NORMAL_NOMAX
    end
  end
end
