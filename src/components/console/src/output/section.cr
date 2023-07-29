require "./io"

# A `ACON::Output::ConsoleOutput` can be divided into multiple sections that can be written to and cleared independently of one another.
#
# Output sections can be used for advanced console outputs, such as displaying multiple progress bars which are updated independently,
# or appending additional rows to tables.
#
# TODO: Implement progress bars and tables.
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   raise ArgumentError.new "This command may only be used with `ACON::Output::ConsoleOutputInterface`." unless output.is_a? ACON::Output::ConsoleOutputInterface
#
#   section1 = output.section
#   section2 = output.section
#
#   section1.puts "Hello"
#   section2.puts "World!"
#   # Output contains "Hello\nWorld!\n"
#
#   sleep 1
#
#   # Replace "Hello" with "Goodbye!"
#   section1.overwrite "Goodbye!"
#   # Output now contains "Goodbye\nWorld!\n"
#
#   sleep 1
#
#   # Clear "World!"
#   section2.clear
#   # Output now contains "Goodbye!\n"
#
#   sleep 1
#
#   # Delete the last 2 lines of the first section
#   section1.clear 2
#   # Output is now empty
#
#   ACON::Command::Status::SUCCESS
# end
# ```
class Athena::Console::Output::Section < Athena::Console::Output::IO
  protected getter lines = 0

  @content = [] of String
  @sections : Array(self)
  @terminal : ACON::Terminal

  def initialize(
    io : ::IO,
    @sections : Array(self),
    verbosity : ACON::Output::Verbosity,
    decorated : Bool,
    formatter : ACON::Formatter::Interface
  )
    super io, verbosity, decorated, formatter

    @terminal = ACON::Terminal.new
    @sections.unshift self
  end

  # Returns the full content string contained within `self`.
  def content : String
    @content.join
  end

  # Clears at most *lines* from `self`.
  # If *lines* is `nil`, all of `self` is cleared.
  def clear(lines : Int32? = nil) : Nil
    return if @content.empty? || !self.decorated?

    if lines && @lines >= lines
      # Double the lines to account for each new line added between content
      @content.delete_at (-lines * 2)..-1
    else
      lines = @lines
      @content.clear
    end

    @lines -= lines

    @io.print self.pop_stream_content_until_current_section(lines)
  end

  # Overrides the current content of `self` with the provided *message*.
  def overwrite(message : String) : Nil
    self.clear
    self.puts message
  end

  protected def add_content(input : String, new_line : Bool = true) : Nil
    width = @terminal.width
    count = input.lines.size - 1
    lines_added = 0

    input.split(ACON::System::EOL).each_with_index do |line, idx|
      if idx < count || new_line || input.ends_with?(ACON::System::EOL)
        line += ACON::System::EOL
      end

      if line.empty?
        next
      end

      if idx.zero? && (last_line = @content.last?) && !last_line.ends_with? ACON::System::EOL
        n = (self.get_display_length(last_line) / width).ceil

        @lines -= n.zero? ? 1 : n.to_i

        line = "#{last_line}#{line}"

        @content[-1, 1] = line
      else
        @content << line
      end

      n = (self.get_display_length(line) / width).ceil

      lines_added += n.zero? ? 1 : n.to_i
    end
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    return super unless self.decorated?

    # Check if the previous line (last entry of @content) needs to be continued
    # i.e. does not end with a line break. In which case, it needs to be erased first
    delete_last_line = ((last_line = (@content.last? || "")) && !last_line.ends_with? ACON::System::EOL)
    erased_content = self.pop_stream_content_until_current_section delete_last_line ? 1 : 0

    self.add_content message, new_line

    # if the last line was removed, re-print its content together with the new content
    # otherwise, just print the new content
    self.io_do_write delete_last_line ? "#{last_line}#{message}" : message, true
    self.io_do_write erased_content, false
  end

  private def get_display_length(input : String) : Int32
    ACON::Helper.width ACON::Helper.remove_decoration(self.formatter, input.gsub("\t", "        "))
  end

  private def pop_stream_content_until_current_section(lines_to_clear_from_current_section : Int32 = 0) : String
    number_of_lines_to_clear = lines_to_clear_from_current_section
    erased_content = Array(String).new

    @sections.each do |section|
      break if self == section

      number_of_lines_to_clear += section.lines

      if section_content = section.content.presence
        if !section_content.ends_with? ACON::System::EOL
          section_content += ACON::System::EOL
        end

        erased_content << section_content
      end
    end

    if number_of_lines_to_clear > 0
      # Move cursor up n lines
      @io.print "\e[#{number_of_lines_to_clear}A"

      # Erase to end of screen
      @io.print "\e[0J"
    end

    erased_content.reverse.join
  end
end
