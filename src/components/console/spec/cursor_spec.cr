require "./spec_helper"

struct CursorTest < ASPEC::TestCase
  @cursor : ACON::Cursor
  @output : ACON::Output::IO

  def initialize
    @output = ACON::Output::IO.new IO::Memory.new
    @cursor = ACON::Cursor.new @output
  end

  def test_move_up_one_line : Nil
    @cursor.move_up
    @output.to_s.should eq "\x1b[1A"
  end

  def test_move_up_multiple_lines : Nil
    @cursor.move_up 12
    @output.to_s.should eq "\x1b[12A"
  end

  def test_move_down_one_line : Nil
    @cursor.move_down
    @output.to_s.should eq "\x1b[1B"
  end

  def test_move_down_multiple_lines : Nil
    @cursor.move_down 12
    @output.to_s.should eq "\x1b[12B"
  end

  def test_move_right_one_line : Nil
    @cursor.move_right
    @output.to_s.should eq "\x1b[1C"
  end

  def test_move_right_multiple_lines : Nil
    @cursor.move_right 12
    @output.to_s.should eq "\x1b[12C"
  end

  def test_move_left_one_line : Nil
    @cursor.move_left
    @output.to_s.should eq "\x1b[1D"
  end

  def test_move_left_multiple_lines : Nil
    @cursor.move_left 12
    @output.to_s.should eq "\x1b[12D"
  end

  def test_move_to_column : Nil
    @cursor.move_to_column 5
    @output.to_s.should eq "\x1b[5G"
  end

  def test_move_to_position : Nil
    @cursor.move_to_position 18, 16
    @output.to_s.should eq "\x1b[17;18H"
  end

  def test_clear_line : Nil
    @cursor.clear_line
    @output.to_s.should eq "\x1b[2K"
  end

  def test_clear_line_after : Nil
    @cursor.clear_line_after
    @output.to_s.should eq "\x1b[K"
  end

  def test_clear_screen : Nil
    @cursor.clear_screen
    @output.to_s.should eq "\x1b[2J"
  end

  def test_save_position : Nil
    @cursor.save_position
    @output.to_s.should eq "\x1b7"
  end

  def test_restore_position : Nil
    @cursor.restore_position
    @output.to_s.should eq "\x1b8"
  end

  def test_hide : Nil
    @cursor.hide
    @output.to_s.should eq "\x1b[?25l"
  end

  def test_show : Nil
    @cursor.show
    @output.to_s.should eq "\x1b[?25h\x1b[?0c"
  end

  def test_clear_output : Nil
    @cursor.clear_output
    @output.to_s.should eq "\x1b[0J"
  end

  def test_current_position : Nil
    @cursor = ACON::Cursor.new @output, IO::Memory.new

    @cursor.move_to_position 10, 10
    position = @cursor.current_position

    @output.to_s.should eq "\x1b[11;10H"

    position.should eq({1, 1})
  end

  def test_current_position_tty : Nil
    pending! "Cursor input must be a TTY" unless STDIN.tty?

    @cursor = ACON::Cursor.new @output

    @cursor.move_to_position 10, 10
    position = @cursor.current_position

    @output.to_s.should eq "\x1b[11;10H"

    position.should_not eq({1, 1})
  end
end
