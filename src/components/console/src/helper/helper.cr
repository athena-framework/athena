require "./interface"

# Contains `ACON::Helper::Interface` implementations that can be used to help with various tasks.
# Such as asking questions, customizing the output format, or generating tables.
#
# This class also acts as a base type that implements common functionality between each helper.
abstract class Athena::Console::Helper
  include Athena::Console::Helper::Interface

  private TIME_FORMATS = {
    {0, "< 1 sec", nil},
    {1, "1 sec", nil},
    {2, "secs", 1},
    {60, "1 min", nil},
    {120, "mins", 60},
    {3_600, "1 hr", nil},
    {7_200, "hrs", 3_600},
    {86_400, "1 day", nil},
    {172_800, "days", 86_400},
  }

  # Formats the provided *span* of time as a human readable string.
  #
  # ```
  # ACON::Helper.format_time 10.seconds # => "10 secs"
  # ACON::Helper.format_time 4.minutes  # => "4 mins"
  # ACON::Helper.format_time 74.minutes # => "1 hr"
  # ```
  def self.format_time(span : Time::Span) : String
    self.format_time span.total_seconds
  end

  # Formats the provided *seconds* as a human readable string.
  #
  # ```
  # ACON::Helper.format_time 10   # => "10 secs"
  # ACON::Helper.format_time 240  # => "4 mins"
  # ACON::Helper.format_time 4400 # => "1 hr"
  # ```
  def self.format_time(seconds : Number) : String
    TIME_FORMATS.each_with_index do |format, idx|
      min_seconds, label, max_seconds = format

      next unless seconds >= min_seconds

      if ((next_format = TIME_FORMATS[idx + 1]?) && (seconds < next_format[0])) || idx == TIME_FORMATS.size - 1
        return label if max_seconds.nil?

        return "#{(seconds // max_seconds).to_i} #{label}"
      end
    end

    raise "BUG: Unable to format time: #{seconds}."
  end

  # Returns a new string with all of its ANSI formatting removed.
  def self.remove_decoration(formatter : ACON::Formatter::Interface, string : String) : String
    is_decorated = formatter.decorated?
    formatter.decorated = false
    string = formatter.format string
    string = string.gsub /\033\[[^m]*m/, ""
    formatter.decorated = is_decorated

    string
  end

  # Returns the width of a string; where the width is how many character positions the string will use.
  #
  # TODO: Support double width chars.
  def self.width(string : String) : Int32
    string.size
  end

  property helper_set : ACON::Helper::HelperSet? = nil
end
