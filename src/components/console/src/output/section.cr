require "./io"

# A `ACON::Output::ConsoleOutput` can be divided into multiple sections that can be written to and cleared independently of one another.
#
# Output sections can be used for advanced console outputs, such as displaying multiple progress bars which are updated independently,
# or appending additional rows to tables.
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
#   sleep 1.second
#
#   # Replace "Hello" with "Goodbye!"
#   section1.overwrite "Goodbye!"
#   # Output now contains "Goodbye\nWorld!\n"
#
#   sleep 1.second
#
#   # Clear "World!"
#   section2.clear
#   # Output now contains "Goodbye!\n"
#
#   sleep 1.second
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
  protected getter max_height : Int32? = nil

  @content = [] of String
  @sections : Array(self)
  @terminal : ACON::Terminal

  def initialize(
    io : ::IO,
    @sections : Array(self),
    verbosity : ACON::Output::Verbosity,
    decorated : Bool,
    formatter : ACON::Formatter::Interface,
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

    if lines && lines > 0
      @content.delete_at -Math.min(lines, @content.size)..
    else
      lines = @lines
      @content.clear
    end

    @lines -= lines

    self.io_do_write self.pop_stream_content_until_current_section((mh = @max_height) ? Math.min(mh, lines) : lines), false
  end

  # Overrides the current content of `self` with the provided *messages*.
  def overwrite(*messages : String) : Nil
    self.overwrite messages
  end

  # Overrides the current content of `self` with the provided *message*.
  def overwrite(message : String | Enumerable(String)) : Nil
    self.clear
    self.puts message
  end

  def max_height=(max_height : Int32?) : Nil
    # Clear output of current section and redraw again with new height
    previous_max_height = @max_height
    @max_height = max_height
    existing_content = self.pop_stream_content_until_current_section previous_max_height ? Math.min(previous_max_height, @lines) : @lines

    self.io_do_write self.visible_content, false
    self.io_do_write existing_content, false
  end

  protected def add_content(input : String, new_line : Bool = true) : Int32
    width = @terminal.width
    lines = input.split EOL, remove_empty: false
    lines_added = 0
    count = lines.size - 1

    lines.each_with_index do |line, idx|
      # re-add the line break that has been removed in `#lines` for:
      # - every line that is not the last line
      # - if new_line is required, also add it to the last line
      if idx < count || new_line
        line += EOL
      end

      # Skip line if there is no text (or new line)
      next if line.empty?

      # For the first line, check if the previous line (last entry of @content) needs to be continued
      # I.e. does not end with a line break
      if idx == 0 && @content[-1]?.try { |l| !l.ends_with? EOL }
        # Deduct the line count of the previous line
        w = (self.get_display_width(@content[-1]) / width).ceil.to_i
        @lines -= w.zero? ? 1 : w

        # Concat previous and new line
        line = "#{@content[-1]}#{line}"

        # Replace last entry of @content with the new expanded line
        @content[-1] = line
      else
        @content << line
      end

      w = (self.get_display_width(line) / width).ceil.to_i
      lines_added += w.zero? ? 1 : w
    end

    @lines += lines_added

    lines_added
  end

  protected def do_write(message : String, new_line : Bool) : Nil
    if !new_line && message.ends_with? EOL
      message = message.chomp
      new_line = true
    end

    unless self.decorated?
      super message, new_line

      return
    end

    # Check if the previous line (last entry of @content) needs to be continued
    # i.e. does not end with a line break. In which case, it needs to be erased first
    lines_to_clear = (last_line = @content[-1]? || "").presence.try { |l| !l.ends_with?(EOL) } ? 1 : 0
    delete_last_line = lines_to_clear == 1

    lines_added = self.add_content message, new_line

    max_height = @max_height || 0

    if line_overflow = (max_height > 0 && @lines > max_height)
      # on overflow, clear the whole section and redraw again (to remove the first lines)
      lines_to_clear = max_height
    end

    erased_content = self.pop_stream_content_until_current_section lines_to_clear

    if line_overflow
      previous_lines_of_section = @content[@lines - max_height, max_height - lines_added]
      self.io_do_write previous_lines_of_section.join(""), false
    end

    # if the last line was removed, re-print its content together with the new content
    # otherwise, just print the new content
    self.io_do_write delete_last_line ? "#{last_line}#{message}" : message, true
    self.io_do_write erased_content, false
  end

  private def get_display_width(input : String) : Int32
    ACON::Helper.width ACON::Helper.remove_decoration(self.formatter, input.gsub("\t", "        "))
  end

  private def pop_stream_content_until_current_section(lines_to_clear_from_current_section : Int32 = 0) : String
    number_of_lines_to_clear = lines_to_clear_from_current_section
    erased_content = Array(String).new

    @sections.each do |section|
      break if self == section

      number_of_lines_to_clear += (max_height = section.max_height) ? Math.min(section.lines, max_height) : section.lines

      unless (section_content = section.visible_content).empty?
        unless section_content.ends_with? EOL
          section_content = "#{section_content}#{EOL}"
        end

        erased_content << section_content
      end
    end

    if number_of_lines_to_clear > 0
      # Move cursor up n lines
      self.io_do_write "\e[#{number_of_lines_to_clear}A", false

      # Erase to end of screen
      self.io_do_write "\e[0J", false
    end

    erased_content.reverse.join
  end

  protected def visible_content : String
    return self.content unless max_height = @max_height

    @content.replace @content[-Math.min(max_height, @content.size)..]

    @content.join
  end
end
