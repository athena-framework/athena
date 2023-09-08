abstract class Athena::Console::Output; end

require "../output/interface"

# :nodoc:
#
# TODO: Consider including this in `athena/contracts`?
module Athena::Console::ClockInterface
  abstract def now : Time
end

class Athena::Console::Helper::ProgressBar
  # :nodoc:
  class Clock
    include Athena::Console::ClockInterface

    def now : Time
      Time.utc
    end
  end

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
    self.formats[name] = format
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
        completed_bars = bar.bar_offset

        display = bar.bar_character * completed_bars

        if completed_bars < bar.bar_width
          empty_bars = bar.bar_width - completed_bars - ACON::Helper.width(ACON::Helper.remove_decoration(output.formatter, bar.progress_character))

          display += "#{bar.progress_character}#{bar.empty_bar_character * empty_bars}"
        end

        display
      end,

      "remaining" => PlaceholderFormatter.new do |bar, output|
        if bar.max_steps.zero?
          raise ACON::Exceptions::Logic.new "Unable to display the remaining time if the maximum number of steps is not set."
        end

        ACON::Helper.format_time bar.remaining
      end,
      "estimated" => PlaceholderFormatter.new do |bar, output|
        if bar.max_steps.zero?
          raise ACON::Exceptions::Logic.new "Unable to display the remaining time if the maximum number of steps is not set."
        end

        ACON::Helper.format_time bar.estimated
      end,

      "memory"  => PlaceholderFormatter.new { |bar| (GC.stats.heap_size - GC.stats.free_bytes).humanize_bytes },
      "elapsed" => PlaceholderFormatter.new { |bar| ACON::Helper.format_time bar.clock.now.to_unix - bar.start_time },
      "current" => PlaceholderFormatter.new { |bar| bar.progress.to_s.rjust bar.step_width, ' ' },
      "max"     => PlaceholderFormatter.new { |bar| bar.max_steps.to_s },
      "percent" => PlaceholderFormatter.new { |bar| (bar.progress_percent * 100).floor.to_i.to_s },
    }
  end

  @output : ACON::Output::Interface
  @terminal : ACON::Terminal
  getter start_time : Int64
  @cursor : ACON::Cursor

  getter bar_width : Int32 = 28
  setter bar_character : String? = nil
  property empty_bar_character : String = "-"
  property progress_character : String = ">"

  setter overwrite : Bool = true
  @max : Int32 = 0
  getter! step_width : Int32

  @redraw_frequency : Int32? = 1
  setter minimum_seconds_between_redraws : Float64 = 0
  setter maximum_seconds_between_redraws : Float64 = 1
  @format : String? = nil
  @internal_format : String? = nil
  @step : Int32 = 0
  @starting_step : Int32 = 0
  @percent : Float64 = 0.0
  @last_write_time : Time = Time::UNIX_EPOCH
  @previous_message : String? = nil
  @write_count : Int32 = 0
  @messages : Hash(String, String) = Hash(String, String).new

  @placeholder_formatters : Hash(String, PlaceholderFormatter) = Hash(String, PlaceholderFormatter).new

  protected property clock : Athena::Console::ClockInterface = Clock.new

  def initialize(output : ACON::Output::Interface, max : Int32? = nil, minimum_seconds_between_redraws : Float64 = 0.04)
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

    @start_time = @clock.now.to_unix
    @cursor = ACON::Cursor.new @output

    self.max_steps = max || 0
  end

  def format=(format : ACON::Helper::ProgressBar::Format)
    self.format = format.to_s.downcase
  end

  def format=(format : String)
    @format = nil
    @internal_format = format
  end

  def progress : Int32
    @step
  end

  def max_steps : Int32
    @max
  end

  def max_steps=(max : Int32) : Nil
    @format = nil
    @max = Math.max 0, max
    @step_width = @max > 0 ? ACON::Helper.width(@max.to_s) : 4
  end

  def progress_percent : Float64
    @percent
  end

  def bar_character : String
    @bar_character || (@max > 0 ? "=" : @empty_bar_character)
  end

  def bar_width=(size : Int32) : Nil
    @bar_width = Math.max 1, size
  end

  def bar_offset : Int32
    if @max > 0
      return (@percent * @bar_width).floor.to_i
    end

    if @redraw_frequency.nil?
      return ((Math.min(5, bar_width / 15) * @write_count) % @bar_width).floor.to_i
    end

    (@step % @bar_width).floor.to_i
  end

  def estimated : Float64
    return 0.0 if @step.zero? || @step == @starting_step

    ((@clock.now.to_unix - @start_time) / (@step - @starting_step) * @max).round
  end

  def remaining : Float64
    return 0.0 if @step.zero?

    ((@clock.now.to_unix - @start_time) / (@step - @starting_step) * (@max - @step)).round 0
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

  def set_message(message : String, name : String = "message") : Nil
    @messages[name] = message
  end

  def message(name : String = "message") : String?
    @messages[name]?
  end

  def redraw_frequency=(steps : Int32?) : Nil
    @redraw_frequency = steps.try { |s| Math.max 1, s }
  end

  def clear : Nil
    return unless @overwrite

    if @format.nil?
      self.set_real_format @internal_format || self.determine_best_format.to_s.downcase
    end

    self.overwrite ""
  end

  def start(max : Int32? = nil, at start_at : Int32 = 0) : Nil
    @start_time = @clock.now.to_unix
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
    if @max > 0 && (step > @max)
      @max = step
    elsif step < 0
      step = 0
    end

    redraw_frequency = @redraw_frequency || ((@max > 0 ? @max : 10) / 10)
    previous_period = @step // redraw_frequency
    current_period = step // redraw_frequency
    @step = step

    @percent = @max > 0 ? @step / @max : 0.0
    time_interval = @clock.now - @last_write_time

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
      self.set_real_format @internal_format || self.determine_best_format.to_s.downcase
    end

    self.overwrite self.build_line
  end

  def finish
    if @max.zero?
      @max = @step
    end

    if @step == @max && !@overwrite
      # Prevent double 100% output
      return
    end

    self.progress = @max
  end

  def iterate(iterator : Enumerable, max : Int32? = nil) : Nil
    self.start max || 0

    iterator.each do |value|
      yield value

      self.advance
    end

    self.finish
  end

  private def overwrite(message : String) : Nil
    return if message == @previous_message

    original_message = message

    if @overwrite
      if previous_message = @previous_message
        if (output = @output).is_a? ACON::Output::Section
          message_lines = previous_message.lines
          line_count = message_lines.size

          message_lines.each do |line|
            message_line_length = ACON::Helper.width ACON::Helper.remove_decoration output.formatter, line

            if message_line_length > @terminal.width
              line_count += message_line_length // @terminal.width
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
    @last_write_time = @clock.now

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
    @format = if @max.zero? && (resolved_format = self.class.format_definition "#{format}_nomax")
                resolved_format
              elsif resolved_format = self.class.format_definition format
                resolved_format
              else
                format
              end
  end

  private def determine_best_format : Format
    case @output.verbosity
    when .debug?        then @max > 0 ? Format::DEBUG : Format::DEBUG_NOMAX
    when .very_verbose? then @max > 0 ? Format::VERY_VERBOSE : Format::VERY_VERBOSE_NOMAX
    when .verbose?      then @max > 0 ? Format::VERBOSE : Format::VERBOSE_NOMAX
    else
      @max > 0 ? Format::NORMAL : Format::NORMAL_NOMAX
    end
  end
end
