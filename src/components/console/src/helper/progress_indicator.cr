class Athena::Console::Helper::ProgressIndicator
  # :nodoc:
  class Clock
    include Athena::Console::ClockInterface

    def now : Time
      Time.utc
    end
  end

  enum Format
    NORMAL
    NORMAL_NO_ANSI

    VERBOSE
    VERBOSE_NO_ANSI

    VERY_VERBOSE
    VERY_VERBOSE_NO_ANSI

    DEBUG
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
      "message"   => PlaceholderFormatter.new { |indicator| indicator.message.to_s },
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
    @indicator_change_interval : Int32 = 100,
    indicator_values : Indexable(String)? = nil
  )
    indicator_values ||= ["-", "\\", "|", "/"]

    if 2 > indicator_values.size
      raise ACON::Exceptions::InvalidArgument.new "Must have at least 2 indicator value characters."
    end

    @format = format || determine_best_format
    @indicator_values = indicator_values
    @start_time = @clock.now.to_unix
  end

  def message=(@message : String?) : Nil
    self.display
  end

  def start(message : String) : Nil
    raise ACON::Exceptions::Logic.new "Progress indicator is already started." if @started

    @message = message
    @started = true
    @start_time = @clock.now.to_unix
    @indicator_update_time = @clock.now.to_unix_ms + @indicator_change_interval
    @indicator_index = 0

    self.display
  end

  def advance : Nil
    raise ACON::Exceptions::Logic.new "Progress indicator has not yet been started." unless @started

    return unless @output.decorated?

    current_time = @clock.now.to_unix_ms

    return if current_time < @indicator_update_time

    @indicator_update_time = current_time + @indicator_change_interval
    @indicator_index += 1

    self.display
  end

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
