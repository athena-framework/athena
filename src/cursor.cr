# Provides an OO way to interact with the console window,
# allows writing on any position of the output.
#
# ```
# class CursorCommand < ACON::Command
#   @@default_name = "cursor"
#
#   protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#     cursor = ACON::Cursor.new output
#
#     # Move the cursor to a specific column, row position.
#     cursor.move_to_position 50, 3
#
#     # Write text at that location.
#     output.puts "Hello!"
#
#     # Clear the current line.
#     cursor.clear_line
#
#     ACON::Command::Status::SUCCESS
#   end
# end
# ```
struct Athena::Console::Cursor
  @output : ACON::Output::Interface
  @input : IO

  def initialize(@output : ACON::Output::Interface, input : IO? = nil)
    @input = input || STDIN
  end

  # Moves the cursor up *lines* lines.
  def move_up(lines : Int32 = 1) : self
    @output.print "\x1b[#{lines}A"

    self
  end

  # Moves the cursor down *lines* lines.
  def move_down(lines : Int32 = 1) : self
    @output.print "\x1b[#{lines}B"

    self
  end

  # Moves the cursor right *lines* lines.
  def move_right(lines : Int32 = 1) : self
    @output.print "\x1b[#{lines}C"

    self
  end

  # Moves the cursor left *lines* lines.
  def move_left(lines : Int32 = 1) : self
    @output.print "\x1b[#{lines}D"

    self
  end

  # Moves the cursor to the provided *column*.
  def move_to_column(column : Int32) : self
    @output.print "\x1b[#{column}G"

    self
  end

  # Moves the cursor to the provided *column*, *row* position.
  def move_to_position(column : Int32, row : Int32) : self
    @output.print "\x1b[#{row + 1};#{column}H"

    self
  end

  # Saves the current position such that it could be restored via `#restore_position`.
  def save_position : self
    @output.print "\x1b7"

    self
  end

  # Restores the position set via `#save_position`.
  def restore_position : self
    @output.print "\x1b8"

    self
  end

  # Hides the cursor.
  def hide : self
    @output.print "\x1b[?25l"

    self
  end

  # Shows the cursor.
  def show : self
    @output.print "\x1b[?25h\x1b[?0c"

    self
  end

  # Clears the current line.
  def clear_line : self
    @output.print "\x1b[2K"

    self
  end

  # Clears the current line after the cursor's current position.
  def clear_line_after : self
    @output.print "\x1b[K"

    self
  end

  # Clears the output from the cursors' current position to the end of the screen.
  def clear_output : self
    @output.print "\x1b[0J"

    self
  end

  # Clears the entire screen.
  def clear_screen : self
    @output.print "\x1b[2J"

    self
  end

  # Returns the current column, row position of the cursor.
  def current_position : {Int32, Int32}
    return {1, 1} unless @input.tty?

    stty_mode = `stty -g`
    system "stty -icanon -echo"

    @input.print "\033[6n"

    bytes = @input.peek

    system "stty #{stty_mode}"

    String.new(bytes.not_nil!).match /\e\[(\d+);(\d+)R/

    {$2.to_i, $1.to_i}
  end
end
