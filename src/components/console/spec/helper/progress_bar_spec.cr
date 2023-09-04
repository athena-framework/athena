require "../spec_helper"

@[ASPEC::TestCase::Focus]
struct ProgressBarTest < ASPEC::TestCase
  @col_size : String?

  def initialize
    @col_size = ENV["COLUMNS"]?
  end

  protected def tear_down : Nil
    if col_size = @col_size
      ENV["COLUMNS"] = col_size
    else
      ENV.delete "COLUMNS"
    end
  end

  def test_multiple_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance
    bar.start

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    1 [->--------------------------]",
      "    0 [>---------------------------]",
    )
  end

  def test_advance : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start at: 15
    bar.advance

    self.assert_output(
      output,
      "   15 [--------------->------------]",
      "   16 [---------------->-----------]",
    )
  end

  def test_resume_with_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 5_000, 0
    bar.start at: 1_000

    self.assert_output(
      output,
      " 1000/5000 [=====>----------------------]  20%",
    )
  end

  @[Pending]
  def test_regular_time_estimation : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 1_200, 0
    bar.start

    bar.advance
    bar.advance

    sleep 1

    bar.estimated.should eq 600
  end

  @[Pending]
  def test_resumed_time_estimation : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 1_200, 0
    bar.start at: 599

    bar.advance

    sleep 1

    bar.estimated.should eq 1_200
    bar.remaining.should eq 600
  end

  def test_advance_with_step : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance 5

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    5 [----->----------------------]",
    )
  end

  def test_advance_multiple_times : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance 3
    bar.advance 2

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    3 [--->------------------------]",
      "    5 [----->----------------------]",
    )
  end

  def test_advance_over_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.progress = 9
    bar.advance
    bar.advance

    self.assert_output(
      output,
      "  9/10 [=========================>--]  90%",
      " 10/10 [============================] 100%",
      " 11/11 [============================] 100%",
    )
  end

  def test_regress : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance
    bar.advance
    bar.advance -1

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    1 [->--------------------------]",
      "    2 [-->-------------------------]",
      "    1 [->--------------------------]"
    )
  end

  def test_regress_multiple_times : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance 3
    bar.advance 3
    bar.advance -1
    bar.advance -2

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    3 [--->------------------------]",
      "    6 [------>---------------------]",
      "    5 [----->----------------------]",
      "    3 [--->------------------------]",
    )
  end

  def test_regress_with_step : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance 4
    bar.advance 4
    bar.advance -2

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      "    4 [---->-----------------------]",
      "    8 [-------->-------------------]",
      "    6 [------>---------------------]"
    )
  end

  def test_regress_below_min : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.progress = 1
    bar.advance -1
    bar.advance -1

    self.assert_output(
      output,
      "  1/10 [==>-------------------------]  10%",
      "  0/10 [>---------------------------]   0%",
    )
  end

  def test_format_max_constructor_no_format : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.start
    bar.advance 10
    bar.finish

    self.assert_output(
      output,
      "  0/10 [>---------------------------]   0%",
      " 10/10 [============================] 100%"
    )
  end

  def test_format_max_start_no_format : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start 10
    bar.advance 10
    bar.finish

    self.assert_output(
      output,
      "  0/10 [>---------------------------]   0%",
      " 10/10 [============================] 100%"
    )
  end

  def test_format_max_constructor_explicit_format_before_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.format = :normal
    bar.start
    bar.advance 10
    bar.finish

    self.assert_output(
      output,
      "  0/10 [>---------------------------]   0%",
      " 10/10 [============================] 100%"
    )
  end

  def test_format_max_start_explicit_format_before_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.format = :normal
    bar.start 10
    bar.advance 10
    bar.finish

    self.assert_output(
      output,
      "  0/10 [>---------------------------]   0%",
      " 10/10 [============================] 100%"
    )
  end

  def test_customiations : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.bar_width = 10
    bar.bar_character = "_"
    bar.empty_bar_character = " "
    bar.progress_character = "/"
    bar.format = " %current%/%max% [%bar%] %percent:3s%%"
    bar.start
    bar.advance

    self.assert_output(
      output,
      "  0/10 [/         ]   0%",
      "  1/10 [_/        ]  10%"
    )
  end

  def test_display_without_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.display

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%"
    )
  end

  def test_display_quiet_verbosity : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output(verbosity: :quiet), 50, 0
    bar.display

    self.assert_output(
      output,
      ""
    )
  end

  def test_finish_without_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.finish

    self.assert_output(
      output,
      " 50/50 [============================] 100%"
    )
  end

  def test_percent : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.start
    bar.display
    bar.advance
    bar.advance

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%",
      "  1/50 [>---------------------------]   2%",
      "  2/50 [=>--------------------------]   4%"
    )
  end

  def test_overwrite_with_shorter_line : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.format = " %current%/%max% [%bar%] %percent:3s%%"
    bar.start
    bar.display
    bar.advance

    # Set short format
    bar.format = " %current%/%max% [%bar%]"
    bar.advance

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%",
      "  1/50 [>---------------------------]   2%",
      "  2/50 [=>--------------------------]"
    )
  end

  def test_overwrite_with_section_output : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.start
    bar.display
    bar.advance
    bar.advance

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%#{ACON::System::EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      "\e[1A\e[0J  2/50 [=>--------------------------]   4%#{ACON::System::EOL}",
      raw: true
    )
  end

  private def generate_output(expected : String) : String
    count = expected.count '\n'

    sub_str = if count > 0
                "\e[1G\e[2K\e[1A" * count
              else
                ""
              end

    "\e[1G\e[2K#{expected}"
  end

  private def output(decorated : Bool = true, verbosity : ACON::Output::Verbosity = :normal) : ACON::Output::Interface
    ACON::Output::IO.new IO::Memory.new, decorated: decorated, verbosity: verbosity
  end

  private def assert_output(output : ACON::Output::Interface, start : String, *frames : String, raw : Bool = false) : Nil
    self.assert_output output, start, frames, raw: raw
  end

  private def assert_output(output : ACON::Output::Interface, start : String, frames : Enumerable(String) = [] of String, *, raw : Bool = false) : Nil
    expected = String.build frames.size + 1 do |io|
      io << start

      frames.each do |frame|
        io << (raw ? frame : self.generate_output(frame))
      end
    end

    output.io.to_s.should eq expected
  end
end
