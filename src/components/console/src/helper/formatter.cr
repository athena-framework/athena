# Provides additional ways to format output messages than `ACON::Formatter::OutputStyle` can do alone, such as:
#
# * Printing messages in a section
# * Printing messages in a block
# * Print truncated messages.
#
# The provided methods return a `String` which could then be passed to `ACON::Output::Interface#print` or `ACON::Output::Interface#puts`.
class Athena::Console::Helper::Formatter < Athena::Console::Helper
  # Prints the provided *message* in the provided *section*.
  # Optionally allows setting the *style* of the section.
  #
  # ```text
  # [SomeSection] Here is some message related to that section
  # ```
  #
  # ```
  # output.puts formatter.format_section "SomeSection", "Here is some message related to that section"
  # ```
  def format_section(section : String, message : String, style : String = "info") : String
    "<#{style}>[#{section}]</#{style}> #{message}"
  end

  # Prints the provided *messages* in a block formatted according to the provided *style*, with a total width a bit more than the longest line.
  #
  # The *large* options adds additional padding, one blank line above and below the messages, and 2 more spaces on the left and right.
  #
  # ```
  # output.puts formatter.format_block({"Error!", "Something went wrong"}, "error", true)
  # ```
  def format_block(messages : String | Enumerable(String), style : String, large : Bool = false)
    messages = messages.is_a?(String) ? {messages} : messages

    len = 0
    lines = [] of String

    messages.each do |message|
      message = ACON::Formatter::Output.escape message
      lines << (large ? "  #{message}  " : " #{message} ")
      len = Math.max (message.size + (large ? 4 : 2)), len
    end

    messages = large ? [" " * len] : [] of String

    lines.each do |line|
      messages << %(#{line}#{" " * (len - line.size)})
    end

    if large
      messages << " " * len
    end

    messages.each_with_index do |line, idx|
      messages[idx] = "<#{style}>#{line}</#{style}>"
    end

    messages.join '\n'
  end

  # Truncates the provided *message* to be at most *length* characters long,
  # with the optional *suffix* appended to the end.
  #
  # ```
  # message = "This is a very long message, which should be truncated"
  # truncated_message = formatter.truncate message, 7
  # output.puts truncated_message # => This is...
  # ```
  #
  # If *length* is negative, it will start truncating from the end.
  #
  # ```
  # message = "This is a very long message, which should be truncated"
  # truncated_message = formatter.truncate message, -4
  # output.puts truncated_message # => This is a very long message, which should be trunc...
  # ```
  def truncate(message : String, length : Int, suffix : String = "...") : String
    computed_length = length - self.class.width suffix

    if computed_length > self.class.width message
      return message
    end

    "#{message[0...length]}#{suffix}"
  end
end
