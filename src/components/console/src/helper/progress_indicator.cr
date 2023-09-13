# Progress indicators are useful to let users know that a command isn't stalled.
# However, unlike `ACON::Helper::ProgressBar`s, these indicators are used when the command's duration is indeterminate,
# such as long-running commands or tasks that are quantifiable.
#
# ![Progress Indicator](../../../img/progress_indicator.gif)
#
# ```
# # Create a new progress indicator.
# indicator = ACON::Helper::ProgressIndicator.new output
#
# # Start and display the progress indicator with a custom message.
# indicator.start "Processing..."
#
# 50.times do
#   # Do work
#
#   # Advance the progress indicator.
#   indicator.advance
# end
#
# # Ensure the progress indicator shows a final completion message
# indicator.finish "Finished!"
# ```
#
# ## Customizing
#
# ### Built-in Formats
#
# The progress indicator comes with a few built-in formats based on the `ACON::Output::Verbosity` the command was executed with:
#
# ```text
# # Verbosity::NORMAL (CLI with no verbosity flag)
#  \ Processing...
#  | Processing...
#  / Processing...
#  - Processing...
#
# # Verbosity::VERBOSE (-v)
#  \ Processing... (1 sec)
#  | Processing... (1 sec)
#  / Processing... (1 sec)
#  - Processing... (1 sec)
#
# # Verbosity::VERY_VERBOSE (-vv) and Verbosity::DEBUG (-vvv)
#  \ Processing... (1 sec, 1kiB)
#  | Processing... (1 sec, 1kiB)
#  / Processing... (1 sec, 1kiB)
#  - Processing... (1 sec, 1kiB)
# ```
#
# NOTE: If a command called with `ACON::Output::Verbosity::QUIET`, the progress bar will not be displayed.
#
# The format may also be set explicitly in code within the constructor:
#
# ```
# # If the progress bar has a maximum number of steps.
# ACON::Helper::ProgressIndicator.new output, format: :very_verbose
# ```
#
# ### Custom Indicator Values
#
# Custom indicator values may also be used:
#
# ```
# indicator = ACON::Helper::ProgressIndicator.new output, indicator_values: %w(⠏ ⠛ ⠹ ⢸ ⣰ ⣤ ⣆ ⡇)
# ```
#
# The progress indicator would now look like:
#
# ```text
# ⠏ Processing...
# ⠛ Processing...
# ⠹ Processing...
# ⢸ Processing...
# ```
#
# ### Custom Placeholders
#
# A progress indicator uses placeholders (a name enclosed with the `%` character) to determine the output format.
# The built-in placeholders include:
#
# * `%indicator%` - The current indicator
# * `%elapsed%` - The time elapsed since the start of the progress indicator
# * `%memory%` - The current memory usage
# * `%message%` - Used to display arbitrary messages
#
# These can be customized via `.set_placeholder_formatter`.
#
# ```
# ACON::Helper::ProgressIndicator.set_placeholder_formatter "message" do
#   # Return any arbitrary string
#   "My Custom Message"
# end
# ```
#
# NOTE: Placeholder customization is global and would affect any indicator used after calling `.set_placeholder_formatter`.
class Athena::Console::Helper::ProgressIndicator
  # :nodoc:
  class Clock
    include Athena::Console::ClockInterface

    def now : Time
      Time.utc
    end
  end

  # Represents the built in progress indicator formats.
  #
  # See [Built-In Formats][Athena::Console::Helper::ProgressIndicator--built-in-formats] for more information.
  enum Format
    # `" %indicator% %message%"`
    NORMAL

    # `" %message%"`
    NORMAL_NO_ANSI

    # `" %indicator% %message% (%elapsed:6s%)"`
    VERBOSE

    # `" %message% (%elapsed:6s%)"`
    VERBOSE_NO_ANSI

    # `" %indicator% %message% (%elapsed:6s%, %memory:6s%)"`
    VERY_VERBOSE

    # `" %message% (%elapsed:6s%, %memory:6s%)"`
    VERY_VERBOSE_NO_ANSI

    # `" %indicator% %message% (%elapsed:6s%, %memory:6s%)"`
    DEBUG

    # `" %message% (%elapsed:6s%, %memory:6s%)"`
    DEBUG_NO_ANSI

    def format : String
      case self
      in .normal?                                then " %indicator% %message%"
      in .normal_no_ansi?                        then " %message%"
      in .verbose?                               then " %indicator% %message% (%elapsed:6s%)"
      in .verbose_no_ansi?                       then " %message% (%elapsed:6s%)"
      in .very_verbose?, .debug?                 then " %indicator% %message% (%elapsed:6s%, %memory:6s%)"
      in .very_verbose_no_ansi?, .debug_no_ansi? then " %message% (%elapsed:6s%, %memory:6s%)"
      end
    end
  end

  # Represents the expected type of a [Placeholder Formatter][Athena::Console::Helper::ProgressIndicator--custom-placeholders].
  alias PlaceholderFormatter = Proc(Athena::Console::Helper::ProgressIndicator, String)

  # INTERNAL
  protected class_getter placeholder_formatters : Hash(String, PlaceholderFormatter) { self.init_placeholder_formatters }

  # Registers a custom placeholder with the provided *name* with the block being the formatter.
  def self.set_placeholder_formatter(name : String, &block : self -> String) : Nil
    self.set_placeholder_formatter name, block
  end

  # Registers a custom placeholder with the provided *name*, using the provided *callable* as the formatter.
  def self.set_placeholder_formatter(name : String, callable : ACON::Helper::ProgressIndicator::PlaceholderFormatter) : Nil
    self.placeholder_formatters[name] = callable
  end

  # Returns the global formatter for the provided *name* if it exists, otherwise `nil`.
  def self.placeholder_formatter(name : String) : ACON::Helper::ProgressIndicator::PlaceholderFormatter?
    self.placeholder_formatters[name]?
  end

  private def self.init_placeholder_formatters : Hash(String, PlaceholderFormatter)
    {
      "elapsed"   => PlaceholderFormatter.new { |indicator| ACON::Helper.format_time indicator.clock.now.to_unix - indicator.start_time },
      "indicator" => PlaceholderFormatter.new { |indicator| indicator.indicator_values[indicator.indicator_index % indicator.indicator_values.size] },
      "memory"    => PlaceholderFormatter.new { (GC.stats.heap_size - GC.stats.free_bytes).humanize_bytes },
      "message"   => PlaceholderFormatter.new(&.message.to_s),
    }
  end

  protected getter indicator_values : Indexable(String)
  protected getter indicator_index : Int32 = 0
  protected getter start_time : Int64

  protected getter message : String? = nil
  protected property clock : Athena::Console::ClockInterface = Clock.new

  @output : ACON::Output::Interface
  @format : Format
  @indicator_change_interval : Int32
  @started : Bool = false
  @indicator_update_time : Int64 = 0

  def initialize(
    @output : ACON::Output::Interface,
    format : ACON::Helper::ProgressIndicator::Format? = nil,
    indicator_change_interval_milliseconds : Int32 = 100,
    indicator_values : Indexable(String)? = nil
  )
    indicator_values ||= ["-", "\\", "|", "/"]

    if 2 > indicator_values.size
      raise ACON::Exceptions::InvalidArgument.new "Must have at least 2 indicator value characters."
    end

    @format = format || determine_best_format
    @indicator_values = indicator_values
    @start_time = @clock.now.to_unix
    @indicator_change_interval = indicator_change_interval_milliseconds
  end

  # Sets the *message* to display alongside the indicator.
  def message=(@message : String?) : Nil
    self.display
  end

  # Starts and displays the indicator with the provided *message*.
  def start(message : String) : Nil
    raise ACON::Exceptions::Logic.new "Progress indicator is already started." if @started

    @message = message
    @started = true
    @start_time = @clock.now.to_unix
    @indicator_update_time = @clock.now.to_unix_ms + @indicator_change_interval
    @indicator_index = 0

    self.display
  end

  # Advance the indicator to display the next indicator character.
  def advance : Nil
    raise ACON::Exceptions::Logic.new "Progress indicator has not yet been started." unless @started

    return unless @output.decorated?

    current_time = @clock.now.to_unix_ms

    return if current_time < @indicator_update_time

    @indicator_update_time = current_time + @indicator_change_interval
    @indicator_index += 1

    self.display
  end

  # Display the current state of the indicator.
  def display : Nil
    return if @output.verbosity.quiet?

    self.overwrite(
      @format.format.gsub /%([a-z\-_]+)(?:\:([^%]+))?%/i do |_, match|
        if formatter = self.class.placeholder_formatter match[1]
          next formatter.call self
        end

        match[0]
      end
    )
  end

  # Completes the indicator with the provided *message*.
  def finish(@message : String) : Nil
    raise ACON::Exceptions::Logic.new "Progress indicator has not yet been started." unless @started

    self.display
    @output.puts ""
    @started = false
  end

  private def overwrite(message : String) : Nil
    if @output.decorated?
      @output.print "\x0D\x1B[2K"
      @output.print message
    else
      @output.puts message
    end
  end

  private def determine_best_format : Format
    case {@output.verbosity, @output.decorated?}
    when {.debug?, true}         then Format::VERY_VERBOSE
    when {.debug?, false}        then Format::VERY_VERBOSE_NO_ANSI
    when {.very_verbose?, true}  then Format::VERY_VERBOSE
    when {.very_verbose?, false} then Format::VERY_VERBOSE_NO_ANSI
    when {.verbose?, true}       then Format::VERBOSE
    when {.verbose?, false}      then Format::VERBOSE_NO_ANSI
    else
      @output.decorated? ? Format::NORMAL : Format::NORMAL_NO_ANSI
    end
  end
end
