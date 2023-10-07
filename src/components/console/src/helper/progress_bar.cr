abstract class Athena::Console::Output; end

require "../output/interface"

# When executing longer-running commands, it can be helpful to show progress information that updates as the command runs:
#
# ![Progress Bar](../../../img/progress_bar.gif)
#
# TIP: Consider using `ACON::Style::Athena` to display a progress bar.
#
# The ProgressBar helper can be used to progress information to any `ACON::Output::Interface`:
#
# ```
# # Create a new progress bar with 50 required units for completion.
# progress_bar = ACON::Helper::ProgressBar.new output, 50
#
# # Start and display the progress bar.
# progress_bar.start
#
# 50.times do
#   # Do work
#
#   # Advance the progress bar by 1 unit.
#   progress_bar.advance
#
#   # Or advance by more than a single unit.
#   # progress_bar.advance 3
# end
#
# # Ensure progress bar is at 100%.
# progress_bar.finish
# ```
#
# A progress bar can also be created without a required number of units, in which case it will just act as a [throbber](https://en.wikipedia.org/wiki/Throbber).
# However, `#max_steps=` can be called at any point to either set, or increase the required number of units.
# E.g. if its only known after performing some calculations, or additional work is needed such that the original value is not invalid.
#
# TIP: Consider using an `ACON::Helper::ProgressIndicator` instead of a progress bar for this use case.
#
# Be sure to call `#finish` when the task completes to ensure the progress bar is refreshed with a 100% completion.
#
# NOTE: By default the progress bar will write its output to `STDERR`, however this can be customized by using an `ACON::Output::IO` explicitly.
#
# If the progress information is stored within an [Enumerable](https://crystal-lang.org/api/Enumerable.html) type, the `#iterate` method
# can be used to start, advance, and finish the progress bar automatically, yielding each item in the collection:
#
# ```
# bar = ACON::Helper::ProgressBar.new output
# arr = [1, 2, 3]
#
# bar.iterate(arr) do |item|
#   # Do something
# end
# ```
#
# Which would output:
# ```text
# 0/2 [>---------------------------]   0%
# 1/2 [==============>-------------]  50%
# 2/2 [============================] 100%
# ```
#
# NOTE: `Iterator` types are also supported, but need the max value provided explicitly via the second argument to `#iterate` if known.
#
# ### Progressing
#
# While the `#advance` method can be used to move the progress bar ahead by a specific number of steps,
# the current step can be set explicitly via `#progress=`.
#
# It is also possible to start the progress bar at a specific step, which is useful when resuming some long-standing task:
#
# ```
# # Create a 100 unit progress bar.
# progress_bar = ACON::Helper::ProgressBar.new output, 100
#
# # Display the progress bar starting at already 25% complete.
# progress_bar.start at: 25
# ```
#
# TIP: The progress can also be regressed (stepped backwards) by providing `#advance` a negative value.
#
# ### Controlling Rendering
#
# If available, [ANCI Escape Codes](https://en.wikipedia.org/wiki/ANSI_escape_code) are used to handle the rendering of the progress bar,
# otherwise updates are added as new lines. `#minimum_seconds_between_redraws=` can be used to prevent the output being flooded.
# `#redraw_frequency=` can be used to to redraw every _N_ iterations. By default, redraw frequency is **100ms** or **10%** of your `#max_steps`.
#
# ## Customizing
#
# ### Built-in Formats
#
# The progress bar comes with a few built-in formats based on the `ACON::Output::Verbosity` the command was executed with:
#
# ```text
# # Verbosity::NORMAL (CLI with no verbosity flag)
#  0/3 [>---------------------------]   0%
#  1/3 [=========>------------------]  33%
#  3/3 [============================] 100%
#
# # Verbosity::VERBOSE (-v)
#  0/3 [>---------------------------]   0%  1 sec
#  1/3 [=========>------------------]  33%  1 sec
#  3/3 [============================] 100%  1 sec
#
# # Verbosity::VERY_VERBOSE (-vv)
#  0/3 [>---------------------------]   0%  1 sec/1 sec
#  1/3 [=========>------------------]  33%  1 sec/1 sec
#  3/3 [============================] 100%  1 sec/1 sec
#
# # Verbosity::DEBUG (-vvv)
#  0/3 [>---------------------------]   0%  1 sec/1 sec  1kiB
#  1/3 [=========>------------------]  33%  1 sec/1 sec  1kiB
#  3/3 [============================] 100%  1 sec/1 sec  1kiB
# ```
#
# NOTE: If a command called with `ACON::Output::Verbosity::QUIET`, the progress bar will not be displayed.
#
# The format may also be set explicitly in code via:
#
# ```
# # If the progress bar has a maximum number of steps.
# bar.format = :very_verbose
#
# # Without a maximum
# bar.format = :very_verbose_nomax
# ```
#
# ### Custom Formats
#
# While the built-in formats are sufficient for most use cases, custom ones may also be defined:
#
# ```
# bar.format = "%bar%"
# ```
#
# Which would set the format to only display the progress bar itself:
#
# ```text
# >---------------------------
# =========>------------------
# ============================
# ```
#
# A progress bar format is a string that contains specific placeholders (a name enclosed with the `%` character);
# the placeholders are replaced based on the current progress of the bar. The built-in placeholders include:
#
# * `%current%` - The current step
# * `%max%` - The maximum number of steps (or zero if there is not one)
# * `%bar%` - The progress bar itself
# * `%percent%` - The percentage of completion (not available if no max is defined)
# * `%elapsed%` - The time elapsed since the start of the progress bar
# * `%remaining%` - The remaining time to complete the task (not available if no max is defined)
# * `%estimated%` - The estimated time to complete the task (not available if no max is defined)
# * `%memory%` - The current memory usage
# * `%message%` - Used to display arbitrary messages, more on this later
#
# For example, the format string for `ACON::Helper::ProgressBar::Format::NORMAL` is `" %current% [%bar%] %elapsed:6s%"`.
# Individual placeholders can have their formatting tweaked by anything that [sprintf](https://crystal-lang.org/api/toplevel.html#sprintf(format_string,args:Array|Tuple):String-class-method) supports
# by separating the name of the placeholder with a `:`.
# The part after the colon will be passed to `sprintf`.
#
# If a format should be used across an entire application, they can be registered globally via `.set_format_definition`:
#
# ```
# ACON::Helper::ProgressBar.set_format_definition "minimal", "Progress: %percent%%"
#
# bar = ACON::Helper::ProgressBar.new output, 3
# bar.format = "minimal"
# ```
#
# Which would output:
#
# ```text
# Progress: 0%
# Progress: 33%
# Progress: 100%
# ```
#
# TIP: It is almost always better to override the built-in formats in order to automatically vary the display based on the verbosity the command is being ran with.
#
# When creating a custom format, be sure to also define a `_nomax` variant if it is using a placeholder that is only available if `#max_steps` is defined.
#
# ```
# ACON::Helper::ProgressBar.set_format_definition "minimal", "%current%/%remaining%"
# ACON::Helper::ProgressBar.set_format_definition "minimal_nomax", "%current%"
#
# bar = ACON::Helper::ProgressBar.new output, 3
# bar.format = "minimal"
# ```
#
# The format will automatically be set to `minimal_nomax` if the bar does not have a maximum number of steps.
#
# TIP: A format can contain any valid ANSI codes, or any `ACON::Formatter::OutputStyleInterface` markup.
#
# TIP: A format may also span multiple lines, which can be useful to also display contextual information (like the first example).
#
# ### Bar Settings
#
# The `bar` placeholder is a bit special in that all of the characters used to display it can be customized:
#
# ```
# # The Finished part of the bar.
# bar.bar_character = "<comment>=</comment>"
#
# # The unfinished part of the bar.
# bar.empty_bar_character = " "
#
# # The progress character.
# bar.progress_character = "|"
#
# # The width of the bar.
# bar.bar_width = 50
# ```
#
# ### Custom Placeholders
#
# Just like the format, custom placeholders may also be defined.
# This can be useful to have a common way of displaying some sort of application specific information between multiple progress bars:
#
# ```
# ACON::Helper::ProgressBar.set_placeholder_formatter "remaining_steps" do |bar|
#   "#{bar.max_steps - bar.progress}"
# end
# ```
#
# From here it could then be used in a format string as `%remaining_steps%` just like any other placeholder.
# `.set_placeholder_formatter` registers the format globally, while `#set_placeholder_formatter` would set it on a specific progress bar.
#
# ### Custom Messages
#
# While there is a built-in `message` placeholder that can be set via `#set_message`, none of the built-in formats include it.
# As such, before displaying these messages, a custom format needs to be defined:
#
# ```
# bar = ACON::Helper::ProgressBar.new output, 100
# bar.format = " %current%/%max% -- %message%"
#
# bar.set_message "Start"
# bar.start # 0/100 -- Start
#
# bar.set_message "Task is in progress..."
# bar.advance # 1/100 -- Task is in progress...
# ```
#
# `#set_message` also allows or an optional second argument, which can be used to have multiple independent messages within the same format string:
#
# ```
# files.each do |file_name|
#   bar.set_message "Importing files..."
#   bar.set_message file_name, "filename"
#   bar.advance # => 2/100 -- Importing files... (foo/bar.txt)
# end
# ```
#
# ## Multiple Progress Bars
#
# When using `ACON::Output::Section`s, multiple progress bars can be displayed at the same time and updated independently:
#
# ```
# output = output.as ACON::Output::ConsoleOutputInterface
#
# section1 = output.section
# section2 = output.section
#
# bar1 = ACON::Helper::ProgressBar.new section1
# bar2 = ACON::Helper::ProgressBar.new section2
#
# bar1.start 100
# bar2.start 100
#
# 100.times do |idx|
#   bar1.advance
#   bar2.advance(4) if idx.divisible_by? 2
#
#   sleep 0.05
# end
# ```
#
# Which would ultimately look something like:
#
# ```text
# 34/100 [=========>------------------]  34%
# 68/100 [===================>--------]  68%
# ```
class Athena::Console::Helper::ProgressBar
  # Represents the built in progress bar formats.
  #
  # See [Built-In Formats][Athena::Console::Helper::ProgressBar--built-in-formats] for more information.
  enum Format
    # `" %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%/%estimated:-6s% %memory:6s%"`
    DEBUG

    # `" %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%/%estimated:-6s%"`
    VERY_VERBOSE

    # `" %current%/%max% [%bar%] %percent:3s%% %elapsed:6s%"`
    VERBOSE

    # `" %current%/%max% [%bar%] %percent:3s%%"`
    NORMAL

    # `" %current% [%bar%] %elapsed:6s% %memory:6s%"`
    DEBUG_NOMAX

    # `" %current% [%bar%] %elapsed:6s%"`
    VERBOSE_NOMAX

    # `" %current% [%bar%] %elapsed:6s%"`
    VERY_VERBOSE_NOMAX

    # `" %current% [%bar%]"`
    NORMAL_NOMAX
  end

  # Represents the expected type of a [Placeholder Formatter][Athena::Console::Helper::ProgressBar--custom-placeholders].
  alias PlaceholderFormatter = Proc(Athena::Console::Helper::ProgressBar, Athena::Console::Output::Interface, String)

  # INTERNAL
  protected class_getter formats : Hash(String, String) { self.init_formats }

  # INTERNAL
  protected class_getter placeholder_formatters : Hash(String, PlaceholderFormatter) { self.init_placeholder_formatters }

  # Registers the *format* globally with the provided *name*.
  def self.set_format_definition(name : String, format : String) : Nil
    self.formats[name] = format
  end

  # Returns the global format string for the provided *name* if it exists, otherwise `nil`.
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

  # Registers a custom placeholder with the provided *name* with the block being the formatter.
  def self.set_placeholder_formatter(name : String, &block : self, ACON::Output::Interface -> String) : Nil
    self.set_placeholder_formatter name, block
  end

  # Registers a custom placeholder with the provided *name*, using the provided *callable* as the formatter.
  def self.set_placeholder_formatter(name : String, callable : ACON::Helper::ProgressBar::PlaceholderFormatter) : Nil
    self.placeholder_formatters[name] = callable
  end

  # Returns the global formatter for the provided *name* if it exists, otherwise `nil`.
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

      "remaining" => PlaceholderFormatter.new do |bar, _|
        if bar.max_steps.zero?
          raise ACON::Exceptions::Logic.new "Unable to display the remaining time if the maximum number of steps is not set."
        end

        ACON::Helper.format_time bar.remaining
      end,
      "estimated" => PlaceholderFormatter.new do |bar, _|
        if bar.max_steps.zero?
          raise ACON::Exceptions::Logic.new "Unable to display the remaining time if the maximum number of steps is not set."
        end

        ACON::Helper.format_time bar.estimated
      end,

      "memory"  => PlaceholderFormatter.new { |_| (GC.stats.heap_size - GC.stats.free_bytes).humanize_bytes },
      "elapsed" => PlaceholderFormatter.new { |bar| ACON::Helper.format_time bar.clock.now - bar.start_time },
      "current" => PlaceholderFormatter.new { |bar| bar.progress.to_s.rjust bar.step_width, ' ' },
      "max"     => PlaceholderFormatter.new(&.max_steps.to_s),
      "percent" => PlaceholderFormatter.new { |bar| (bar.progress_percent * 100).floor.to_i.to_s },
    }
  end

  @output : ACON::Output::Interface
  @terminal : ACON::Terminal
  @cursor : ACON::Cursor

  @max : Int32 = 0
  @redraw_frequency : Int32? = 1
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

  protected getter clock : ACLK::Interface

  # Returns the time the progress bar was started as a Unix epoch.
  getter start_time : Time

  # Returns the width of the progress bar in pixels.
  #
  # ```
  # bar1 = ...
  # bar1.bar_width = 50
  # bar1.start 10
  #
  # bar2 = ...
  # bar2.bar_width = 10
  # bar2.start 20
  #
  # bar1.finish
  # bar2.finish
  # ```
  #
  # ```
  # 10/10 [==================================================] 100%
  # 20/20 [==========] 100%
  # ```
  getter bar_width : Int32 = 28

  # Explicitly sets the character to use for the finished part of the bar.
  setter bar_character : String? = nil

  # Represents the character used for the unfinished part of the bar.
  property empty_bar_character : String = "-"

  # Represents the character used for the current progress of the bar.
  property progress_character : String = ">"

  # Sets if the progress bar should overwrite the progress bar.
  # Set to `false` in order to print the progress bar on a new line for each update.
  setter overwrite : Bool = true

  # Returns the width in pixels that the current `#progress` takes up when displayed.
  getter! step_width : Int32

  # Sets the minimum amount of time between redraws.
  #
  # See [Controlling Rendering][Athena::Console::Helper::ProgressBar--controlling-rendering] for more information.
  setter minimum_seconds_between_redraws : Float64 = 0

  # Sets the maximum amount of time between redraws.
  #
  # See [Controlling Rendering][Athena::Console::Helper::ProgressBar--controlling-rendering] for more information.
  setter maximum_seconds_between_redraws : Float64 = 1

  def initialize(
    output : ACON::Output::Interface,
    max : Int32? = nil,
    minimum_seconds_between_redraws : Float64 = 0.04,

    # Use a monotonic clock by default since its better for measuring time
    @clock : ACLK::Interface = ACLK::Monotonic.new
  )
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

    @start_time = @clock.now
    @cursor = ACON::Cursor.new @output

    self.max_steps = max || 0
  end

  # Sets what built in *format* to use.
  # See [Built-in Formats][Athena::Console::Helper::ProgressBar--built-in-formats] for more information.
  def format=(format : ACON::Helper::ProgressBar::Format)
    self.format = format.to_s.downcase
  end

  # Sets the format string used to determine how to display the progress bar.
  # See [Custom Formats][Athena::Console::Helper::ProgressBar--custom-formats] for more information.
  def format=(format : String)
    @format = nil
    @internal_format = format
  end

  # Returns the current step of the progress bar
  def progress : Int32
    @step
  end

  # Returns the maximum number of possible steps, or `0` if it is unknown.
  def max_steps : Int32
    @max
  end

  # Sets the maximum possible steps to the provided *max*.
  def max_steps=(max : Int32) : Nil
    @format = nil
    @max = Math.max 0, max
    @step_width = @max > 0 ? ACON::Helper.width(@max.to_s) : 4
  end

  # Returns the a percent of progress of `#progress` versus `#max_steps`.
  # Returns zero if there is no max defined.
  def progress_percent : Float64
    @percent
  end

  # Returns the character to use for the finished part of the bar.
  def bar_character : String
    @bar_character || (@max > 0 ? "=" : @empty_bar_character)
  end

  # Sets the width of the bar in pixels to the provided *size*.
  # See `#bar_width`.
  def bar_width=(size : Int32) : Nil
    @bar_width = Math.max 1, size
  end

  # Returns the amount of `#bar_character` representing the current `#progress`.
  def bar_offset : Int32
    if @max > 0
      return (@percent * @bar_width).floor.to_i
    end

    if @redraw_frequency.nil?
      return ((Math.min(5, bar_width / 15) * @write_count) % @bar_width).floor.to_i
    end

    (@step % @bar_width).floor.to_i
  end

  # Returns an estimated amount of time in seconds until the progress bar is completed.
  def estimated : Float64
    return 0.0 if @step.zero? || @step == @starting_step

    ((@clock.now - @start_time).total_seconds / (@step - @starting_step) * @max).round
  end

  # Returns an estimated total amount of time in seconds needed for the progress bar to complete.
  def remaining : Float64
    return 0.0 if @step.zero?

    ((@clock.now - @start_time).total_seconds / (@step - @starting_step) * (@max - @step)).round 0
  end

  # Returns the amount of time in seconds until the progress bar is completed.
  def placeholder_formatter(name : String) : ACON::Helper::ProgressBar::PlaceholderFormatter?
    @placeholder_formatters[name]? || self.class.placeholder_formatter name
  end

  # Same as `.set_placeholder_formatter`, but scoped to this particular progress bar.
  def set_placeholder_formatter(name : String, &block : self, ACON::Output::Interface -> String) : Nil
    self.set_placeholder_formatter name, block
  end

  # Same as `.set_placeholder_formatter`, but scoped to this particular progress bar.
  def set_placeholder_formatter(name : String, callable : ACON::Helper::ProgressBar::PlaceholderFormatter) : Nil
    @placeholder_formatters[name] = callable
  end

  # Sets the message with the provided *name* to that of the provided *message*.
  def set_message(message : String, name : String = "message") : Nil
    @messages[name] = message
  end

  # Returns the message associated with the provided *name* if defined, otherwise `nil`.
  def message(name : String = "message") : String?
    @messages[name]?
  end

  # Redraw the progress bar every after advancing the provided amount of *steps*.
  #
  #  See [Controlling Rendering][Athena::Console::Helper::ProgressBar--controlling-rendering] for more information.
  def redraw_frequency=(steps : Int32?) : Nil
    @redraw_frequency = steps.try { |s| Math.max 1, s }
  end

  # Clears the progress bar from the output.
  # Can be used in conjunction with `#display` to allow outputting something while a progress bar is running.
  # Call `#clear`, write the content, then call `#display` to show the progress bar again.
  #
  # NOTE: Requires that `#overwrite=` be set to `true`.
  def clear : Nil
    return unless @overwrite

    if @format.nil?
      self.set_real_format @internal_format || self.determine_best_format.to_s.downcase
    end

    self.overwrite ""
  end

  # Starts the progress bar.
  #
  # Optionally sets the maximum number of steps to *max*, or `nil` to leave unchanged.
  # Optionally starts the progress bar *at* the provided step.
  def start(max : Int32? = nil, at start_at : Int32 = 0) : Nil
    @start_time = @clock.now
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

  # Advanced the progress bar *by* the provided number of steps.
  def advance(by step : Int32 = 1) : Nil
    self.progress = @step + step
  end

  # Explicitly sets the current step number of the progress bar.
  #
  # ameba:disable Metrics/CyclomaticComplexity
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

  # Displays the progress bar's current state.
  def display : Nil
    return if @output.verbosity.quiet?

    if @format.nil?
      self.set_real_format @internal_format || self.determine_best_format.to_s.downcase
    end

    self.overwrite self.build_line
  end

  # Finishes the progress output, making it 100% complete.
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

  # Start, advance, and finish the progress bar automatically, yielding each item in the provided *enumerable*.
  #
  # ```
  # bar = ACON::Helper::ProgressBar.new output
  # arr = [1, 2, 3]
  #
  # bar.iterate(arr) do |item|
  #   # Do something
  # end
  # ```
  #
  # Which would output:
  # ```
  # 0/2 [>---------------------------]   0%
  # 1/2 [==============>-------------]  50%
  # 2/2 [============================] 100%
  # ```
  #
  # NOTE: `Iterator` types are also supported, but need the max value provided explicitly via the second argument to `#iterate` if known.
  def iterate(enumerable : Enumerable(T), max : Int32? = nil, & : T -> Nil) : Nil forall T
    self.start(enumerable.is_a?(Indexable) ? enumerable.size : 0)

    enumerable.each do |value|
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
          previous_message.count('\n').times do |_|
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

    callback = Proc(String, Regex::MatchData, String).new do |_, match|
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
