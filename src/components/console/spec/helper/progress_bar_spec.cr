require "../spec_helper"

struct ProgressBarTest < ASPEC::TestCase
  @clock : ACLK::Spec::MockClock

  def initialize
    ENV["COLUMNS"] = "120"
    @clock = ACLK::Spec::MockClock.new
  end

  protected def tear_down : Nil
    ENV.delete "COLUMNS"
  end

  def test_multiple_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance
    bar.start

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    1 [->--------------------------]"),
      self.generate_output("    0 [>---------------------------]"),
    )
  end

  def test_advance : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start at: 15
    bar.advance

    self.assert_output(
      output,
      "   15 [--------------->------------]",
      self.generate_output("   16 [---------------->-----------]"),
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

  def test_regular_time_estimation : Nil
    bar = ACON::Helper::ProgressBar.new self.output, 1_200, 0, clock: @clock

    bar.start
    bar.advance
    bar.advance

    @clock.sleep 1.second

    bar.estimated.should eq 600
  end

  def test_resumed_time_estimation : Nil
    bar = ACON::Helper::ProgressBar.new self.output, 1_200, 0, clock: @clock

    bar.start at: 599
    bar.advance

    @clock.sleep 1.second

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
      self.generate_output("    5 [----->----------------------]"),
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
      self.generate_output("    3 [--->------------------------]"),
      self.generate_output("    5 [----->----------------------]"),
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
      self.generate_output(" 10/10 [============================] 100%"),
      self.generate_output(" 11/11 [============================] 100%"),
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
      self.generate_output("    1 [->--------------------------]"),
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("    1 [->--------------------------]"),
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
      self.generate_output("    3 [--->------------------------]"),
      self.generate_output("    6 [------>---------------------]"),
      self.generate_output("    5 [----->----------------------]"),
      self.generate_output("    3 [--->------------------------]"),
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
      self.generate_output("    4 [---->-----------------------]"),
      self.generate_output("    8 [-------->-------------------]"),
      self.generate_output("    6 [------>---------------------]"),
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
      self.generate_output("  0/10 [>---------------------------]   0%"),
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
      self.generate_output(" 10/10 [============================] 100%"),
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
      self.generate_output(" 10/10 [============================] 100%"),
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
      self.generate_output(" 10/10 [============================] 100%"),
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
      self.generate_output(" 10/10 [============================] 100%")
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
      self.generate_output("  1/10 [_/        ]  10%"),
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
      self.generate_output("  1/50 [>---------------------------]   2%"),
      self.generate_output("  2/50 [=>--------------------------]   4%"),
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
      self.generate_output("  1/50 [>---------------------------]   2%"),
      self.generate_output("  2/50 [=>--------------------------]"),
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
      "  0/50 [>---------------------------]   0%#{EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{EOL}",
      "\e[1A\e[0J  2/50 [=>--------------------------]   4%#{EOL}",
    )
  end

  def test_overwrite_with_ansi_section_output : Nil
    ENV["COLUMNS"] = "43"

    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.format = " \033[44;37m%current%/%max%\033[0m [%bar%] %percent:3s%%"
    bar.start
    bar.display
    bar.advance
    bar.advance

    self.assert_output(
      output,
      " \033[44;37m 0/50\033[0m [>---------------------------]   0%#{EOL}",
      "\e[1A\e[0J \033[44;37m 1/50\033[0m [>---------------------------]   2%#{EOL}",
      "\e[1A\e[0J \033[44;37m 2/50\033[0m [=>--------------------------]   4%#{EOL}",
    )
  end

  def test_overwrite_multiple_progress_bars_with_section_output : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output1 = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar1 = ACON::Helper::ProgressBar.new output1, 50, 0
    bar2 = ACON::Helper::ProgressBar.new output2, 50, 0

    bar1.start
    bar2.start

    bar2.advance
    bar1.advance

    self.assert_output(
      acon_output,
      "  0/50 [>---------------------------]   0%#{EOL}",
      "  0/50 [>---------------------------]   0%#{EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{EOL}",
      "\e[2A\e[0J  1/50 [>---------------------------]   2%#{EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{EOL}",
      "  1/50 [>---------------------------]   2%#{EOL}",
    )
  end

  def test_message : Nil
    bar = ACON::Helper::ProgressBar.new self.output, minimum_seconds_between_redraws: 0
    bar.message.should be_nil
    bar.set_message "other message", "other-message"
    bar.set_message "my message"

    bar.message.should eq "my message"
    bar.message("other-message").should eq "other message"
  end

  def test_overwrite_with_new_lines_in_message : Nil
    ACON::Helper::ProgressBar.set_format_definition "test", "%current%/%max% [%bar%] %percent:3s%% %message% EXISTING TEXT."

    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.format = "test"
    bar.start
    bar.display
    bar.set_message "MESSAGE\nTEXT!"
    bar.advance
    bar.set_message "OTHER\nTEXT!"
    bar.advance

    self.assert_output(
      output,
      " 0/50 [>---------------------------]   0% %message% EXISTING TEXT.",
      "\e[1G\e[2K 1/50 [>---------------------------]   2% MESSAGE\nTEXT! EXISTING TEXT.",
      "\e[1G\e[2K\e[1A\e[1G\e[2K 2/50 [=>--------------------------]   4% OTHER\nTEXT! EXISTING TEXT.",
    )
  end

  def test_overwrite_with_section_output_with_newlines_in_message : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new
    ACON::Helper::ProgressBar.set_format_definition "test", "%current%/%max% [%bar%] %percent:3s%% %message% EXISTING TEXT."

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.format = "test"
    bar.start
    bar.display
    bar.set_message "MESSAGE\nTEXT!"
    bar.advance
    bar.set_message "OTHER\nTEXT!"
    bar.advance

    self.assert_output(
      output,
      " 0/50 [>---------------------------]   0% %message% EXISTING TEXT.#{EOL}",
      "\e[1A\e[0J 1/50 [>---------------------------]   2% MESSAGE\nTEXT! EXISTING TEXT.#{EOL}",
      "\e[2A\e[0J 2/50 [=>--------------------------]   4% OTHER\nTEXT! EXISTING TEXT.#{EOL}",
    )
  end

  def test_multiple_sections_with_custom_format : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output1 = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new
    output2 = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    ACON::Helper::ProgressBar.set_format_definition "custom", "%current%/%max% [%bar%] %percent:3s%% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee."

    bar1 = ACON::Helper::ProgressBar.new output1, 50, 0
    bar2 = ACON::Helper::ProgressBar.new output2, 50, 0
    bar2.format = "custom"

    bar1.start
    bar2.start

    bar1.advance
    bar2.advance

    self.assert_output(
      acon_output,
      "  0/50 [>---------------------------]   0%#{EOL}",
      " 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{EOL}",
      "\e[4A\e[0J 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{EOL}",
      "\e[3A\e[0J  1/50 [>---------------------------]   2%#{EOL}",
      " 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{EOL}",
      "\e[3A\e[0J 1/50 [>]   2% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{EOL}",
    )
  end

  def test_start_with_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.format = "%current%/%max% [%bar%]"
    bar.start 50
    bar.advance

    self.assert_output(
      output,
      " 0/50 [>---------------------------]",
      self.generate_output(" 1/50 [>---------------------------]"),
    )
  end

  def test_set_current_progress : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.start
    bar.display
    bar.advance
    bar.progress = 15
    bar.progress = 25

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%",
      self.generate_output("  1/50 [>---------------------------]   2%"),
      self.generate_output(" 15/50 [========>-------------------]  30%"),
      self.generate_output(" 25/50 [==============>-------------]  50%"),
    )
  end

  def test_set_current_progress_before_start : Nil
    bar = ACON::Helper::ProgressBar.new self.output, minimum_seconds_between_redraws: 0
    bar.progress = 15
    bar.start_time.should_not be_nil
  end

  def test_redraw_frequency : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 6, 0
    bar.redraw_frequency = 2
    bar.start
    bar.progress = 1
    bar.advance 2
    bar.advance 2
    bar.advance

    self.assert_output(
      output,
      " 0/6 [>---------------------------]   0%",
      self.generate_output(" 3/6 [==============>-------------]  50%"),
      self.generate_output(" 5/6 [=======================>----]  83%"),
      self.generate_output(" 6/6 [============================] 100%"),
    )
  end

  def test_redraw_frequency_is_at_least_one_if_zero_given : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.redraw_frequency = 0
    bar.start
    bar.advance

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    1 [->--------------------------]"),
    )
  end

  def test_redraw_frequency_is_at_least_one_if_negative_given : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.redraw_frequency = -1
    bar.start
    bar.advance

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    1 [->--------------------------]"),
    )
  end

  def test_multi_byte_support : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.bar_character = "■"
    bar.advance 3

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    3 [■■■>------------------------]"),
    )
  end

  def test_clear : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 50, 0
    bar.start
    bar.advance 25
    bar.clear

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%",
      self.generate_output(" 25/50 [==============>-------------]  50%"),
      self.generate_output(""),
    )
  end

  def test_percent_not_hundred_before_complete : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 200, 0
    bar.start
    bar.display
    bar.advance 199
    bar.advance

    self.assert_output(
      output,
      "   0/200 [>---------------------------]   0%",
      self.generate_output(" 199/200 [===========================>]  99%"),
      self.generate_output(" 200/200 [============================] 100%"),
    )
  end

  def test_non_decorated_output : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output(decorated: false), 200, 0
    bar.start

    200.times do
      bar.advance
    end

    bar.finish

    self.assert_output(
      output,
      "   0/200 [>---------------------------]   0%#{EOL}",
      "  20/200 [==>-------------------------]  10%#{EOL}",
      "  40/200 [=====>----------------------]  20%#{EOL}",
      "  60/200 [========>-------------------]  30%#{EOL}",
      "  80/200 [===========>----------------]  40%#{EOL}",
      " 100/200 [==============>-------------]  50%#{EOL}",
      " 120/200 [================>-----------]  60%#{EOL}",
      " 140/200 [===================>--------]  70%#{EOL}",
      " 160/200 [======================>-----]  80%#{EOL}",
      " 180/200 [=========================>--]  90%#{EOL}",
      " 200/200 [============================] 100%",
    )
  end

  def test_non_decorated_output_with_clear : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output(decorated: false), 50, 0
    bar.start
    bar.progress = 25
    bar.clear
    bar.progress = 50
    bar.finish

    self.assert_output(
      output,
      "  0/50 [>---------------------------]   0%#{EOL}",
      " 25/50 [==============>-------------]  50%#{EOL}",
      " 50/50 [============================] 100%",
    )
  end

  def test_non_decorated_output_without_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output(decorated: false), minimum_seconds_between_redraws: 0
    bar.start
    bar.advance

    self.assert_output(
      output,
      "    0 [>---------------------------]#{EOL}",
      "    1 [->--------------------------]",
    )
  end

  def test_parallel_bars : Nil
    output = self.output
    bar1 = ACON::Helper::ProgressBar.new output, 2, minimum_seconds_between_redraws: 0
    bar2 = ACON::Helper::ProgressBar.new output, 3, minimum_seconds_between_redraws: 0
    bar2.progress_character = "#"
    bar3 = ACON::Helper::ProgressBar.new output, minimum_seconds_between_redraws: 0

    bar1.start
    output.print "\n"
    bar2.start
    output.print "\n"
    bar3.start

    1.upto 3 do |idx|
      # Up two lines
      output.print "\033[2A"

      if idx <= 2
        bar1.advance
      end

      output.print "\n"
      bar2.advance
      output.print "\n"
      bar3.advance
    end

    output.print "\033[2A"
    output.print "\n"
    output.print "\n"
    bar3.finish

    self.assert_output(
      output,
      " 0/2 [>---------------------------]   0%\n",
      " 0/3 [#---------------------------]   0%\n",
      "    0 [>---------------------------]",

      "\033[2A",
      self.generate_output(" 1/2 [==============>-------------]  50%"),
      "\n",
      self.generate_output(" 1/3 [=========#------------------]  33%"),
      "\n",
      self.generate_output("    1 [->--------------------------]").rstrip,

      "\033[2A",
      self.generate_output(" 2/2 [============================] 100%"),
      "\n",
      self.generate_output(" 2/3 [==================#---------]  66%"),
      "\n",
      self.generate_output("    2 [-->-------------------------]").rstrip,

      "\033[2A",
      "\n",
      self.generate_output(" 3/3 [============================] 100%"),
      "\n",
      self.generate_output("    3 [--->------------------------]").rstrip,

      "\033[2A",
      "\n",
      "\n",
      self.generate_output("    3 [============================]").rstrip,
    )
  end

  def test_without_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.advance
    bar.advance
    bar.advance
    bar.finish

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    1 [->--------------------------]"),
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("    3 [--->------------------------]"),
      self.generate_output("    3 [============================]"),
    )
  end

  def test_setting_max_during_progression : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.start
    bar.progress = 2
    bar.max_steps = 10
    bar.progress = 5
    bar.max_steps = 100
    bar.progress = 10
    bar.finish

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("  5/10 [==============>-------------]  50%"),
      self.generate_output("  10/100 [==>-------------------------]  10%"),
      self.generate_output(" 100/100 [============================] 100%"),
    )
  end

  def test_with_small_screen : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0

    ENV["COLUMNS"] = "12"
    bar.start
    bar.advance
    ENV["COLUMNS"] = "120"

    self.assert_output(
      output,
      "    0 [>---]",
      self.generate_output("    1 [->--]"),
    )
  end

  def test_custom_placeholder_format : Nil
    ACON::Helper::ProgressBar.set_placeholder_formatter "remaining_steps" do |bar|
      "#{bar.max_steps - bar.progress}"
    end

    bar = ACON::Helper::ProgressBar.new output = self.output, 3, 0
    bar.format = " %remaining_steps% [%bar%]"

    bar.start
    bar.advance
    bar.finish

    self.assert_output(
      output,
      " 3 [>---------------------------]",
      self.generate_output(" 2 [=========>------------------]"),
      self.generate_output(" 0 [============================]"),
    )
  end

  def test_adding_instance_placeholder_formatter : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 3, 0
    bar.format = " %countdown% [%bar%]"
    bar.set_placeholder_formatter "countdown" do
      "#{bar.max_steps - bar.progress}"
    end

    bar.start
    bar.advance
    bar.finish

    self.assert_output(
      output,
      " 3 [>---------------------------]",
      self.generate_output(" 2 [=========>------------------]"),
      self.generate_output(" 0 [============================]"),
    )
  end

  def test_multiline_format : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 3, 0
    bar.format = "%bar%\nfoobar"

    bar.start
    bar.advance
    bar.clear
    bar.finish

    self.assert_output(
      output,
      ">---------------------------\nfoobar",
      self.generate_output("=========>------------------\nfoobar"),
      "\e[1G\e[2K\e[1A",
      self.generate_output(""),
      self.generate_output("============================"),
      "\nfoobar",
    )
  end

  def test_set_format_no_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.format = :normal
    bar.start

    self.assert_output(
      output,
      "    0 [>---------------------------]",
    )
  end

  def test_set_format_with_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.format = :normal
    bar.start

    self.assert_output(
      output,
      "  0/10 [>---------------------------]   0%",
    )
  end

  def test_unicode : Nil
    ACON::Helper::ProgressBar.set_format_definition(
      "test",
      "%current%/%max% [%bar%] %percent:3s%% %message% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee."
    )

    bar = ACON::Helper::ProgressBar.new output = self.output, 10, 0
    bar.format = "test"
    bar.progress_character = "💧"
    bar.start

    output.io.to_s.should contain " 0/10 [💧]   0%"
  end

  @[TestWith(
    {"debug"},
    {"very_verbose"},
    {"verbose"},
    {"normal"},
  )]
  def test_formats_without_max(format : String) : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
    bar.format = format
    bar.start

    output.io.to_s.should_not be_empty
  end

  def test_bar_width_with_multiline_format : Nil
    ENV["COLUMNS"] = "10"

    bar = ACON::Helper::ProgressBar.new self.output, minimum_seconds_between_redraws: 0
    bar.format = "%bar%\n0123456789"

    # Before starting
    bar.bar_width = 5
    bar.bar_width.should eq 5

    # After starting
    bar.start
    bar.bar_width.should eq 5

    ENV["COLUMNS"] = "120"
  end

  def test_min_and_max_seconds_between_redraws : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, clock: @clock
    bar.redraw_frequency = 1
    bar.minimum_seconds_between_redraws = 5
    bar.maximum_seconds_between_redraws = 10

    bar.start
    bar.progress = 1
    @clock.sleep 10.seconds
    bar.progress = 2
    @clock.sleep 20.seconds
    bar.progress = 3

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("    3 [--->------------------------]"),
    )
  end

  def test_max_seconds_between_redraws : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0, clock: @clock
    bar.redraw_frequency = 4 # Disable step based redraw
    bar.start

    bar.progress = 1 # No threshold hit, no redraw
    bar.maximum_seconds_between_redraws = 2
    @clock.sleep 1.second
    bar.progress = 2 # Still no redraw because it takes 2 seconds for a redraw
    @clock.sleep 1.second
    bar.progress = 3 # 1 + 1 = 2 -> redraw
    bar.progress = 4 # step based redraw freq hit, redraw even without sleep
    bar.progress = 5 # No threshold hit, no redraw
    bar.maximum_seconds_between_redraws = 3
    @clock.sleep 2.seconds
    bar.progress = 6 # No redraw even though 2 seconds passed. Throttling has priority
    bar.maximum_seconds_between_redraws = 2
    bar.progress = 7 # Throttling relaxed, draw

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    3 [--->------------------------]"),
      self.generate_output("    4 [---->-----------------------]"),
      self.generate_output("    7 [------->--------------------]"),
    )
  end

  def test_min_seconds_between_redraws : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0, clock: @clock
    bar.redraw_frequency = 1
    bar.minimum_seconds_between_redraws = 1
    bar.start

    bar.progress = 1 # Too fast, should not draw
    @clock.sleep 1.second
    bar.progress = 2 # 1 second passed, draw
    bar.minimum_seconds_between_redraws = 2
    @clock.sleep 1.second
    bar.progress = 3 # 1 second passed, but the threshold was changed, should not draw
    @clock.sleep 1.second
    bar.progress = 4 # 1 + 1 seconds = 2 seconds passed, draw
    bar.progress = 5 # No threshold hit, should not draw

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("    4 [---->-----------------------]"),
    )
  end

  def test_no_write_when_message_is_same : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 2
    bar.start
    bar.advance
    bar.display

    self.assert_output(
      output,
      " 0/2 [>---------------------------]   0%",
      self.generate_output(" 1/2 [==============>-------------]  50%"),
    )
  end

  def test_iterate : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0

    result = [] of Int32

    bar.iterate [1, 2] do |value|
      result << value
    end

    result.should eq [1, 2]

    self.assert_output(
      output,
      " 0/2 [>---------------------------]   0%",
      self.generate_output(" 1/2 [==============>-------------]  50%"),
      self.generate_output(" 2/2 [============================] 100%"),
    )
  end

  def test_iterate_iterator : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0

    result = [] of Int32

    bar.iterate [1, 2].each do |value|
      result << value
    end

    result.should eq [1, 2]

    self.assert_output(
      output,
      "    0 [>---------------------------]",
      self.generate_output("    1 [->--------------------------]"),
      self.generate_output("    2 [-->-------------------------]"),
      self.generate_output("    2 [============================]"),
    )
  end

  def test_ansi_colors_and_emojis : Nil
    ENV["COLUMNS"] = "156"
    idx = 0

    ACON::Helper::ProgressBar.set_placeholder_formatter "custom_memory" do
      mem = 100_000 * idx

      colors = idx.zero? ? "44;37" : "41;37"
      idx += 1

      "\033[#{colors}m #{mem.humanize_bytes} \033[0m"
    end

    bar = ACON::Helper::ProgressBar.new output = self.output, 15, 0
    bar.format = " \033[44;37m %title:-37s% \033[0m\n %current%/%max% %bar% %percent:3s%%\n 🏁  %remaining:-10s% %custom_memory:37s%"
    bar.bar_character = done = "\033[32m●\033[0m"
    bar.empty_bar_character = empty = "\033[31m●\033[0m"
    bar.progress_character = progress = "\033[32m➤ \033[0m"

    bar.set_message "Starting the demo... fingers crossed", "title"
    bar.start

    self.assert_output(
      output,
      " \033[44;37m Starting the demo... fingers crossed  \033[0m\n",
      "  0/15 #{progress}#{empty * 26}   0%\n",
      " \xf0\x9f\x8f\x81  < 1 sec                         \033[44;37m 0B \033[0m",
    )

    output.io.as(IO::Memory).clear

    bar.set_message "Looks good to me...", "title"
    bar.advance 4

    self.assert_output(
      output,
      self.generate_output(
        " \033[44;37m Looks good to me...                   \033[0m\n",
        "  4/15 #{done * 7}#{progress}#{empty * 19}  26%\n",
        " \xf0\x9f\x8f\x81  < 1 sec                      \033[41;37m 98kiB \033[0m",
      )
    )

    output.io.as(IO::Memory).clear

    bar.set_message "Thanks, bye", "title"
    bar.finish

    self.assert_output(
      output,
      self.generate_output(
        " \033[44;37m Thanks, bye                           \033[0m\n",
        " 15/15 #{done * 28} 100%\n",
        " \xf0\x9f\x8f\x81  < 1 sec                     \033[41;37m 195kiB \033[0m",
      )
    )

    ENV["COLUMNS"] = "120"
  end

  def test_multiline_format_is_fully_cleared : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 3
    bar.format = "%current%/%max%\n%message%\nFoo"

    bar.set_message "1234567890"
    bar.start
    bar.display

    bar.set_message "ABC"
    bar.advance
    bar.display

    bar.set_message "A"
    bar.advance
    bar.display

    bar.finish

    self.assert_output(
      output,
      "0/3\n1234567890\nFoo",
      self.generate_output("1/3\nABC\nFoo"),
      self.generate_output("2/3\nA\nFoo"),
      self.generate_output("3/3\nA\nFoo"),
    )
  end

  def test_multiline_format_is_fully_correct_with_manual_cleanup : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output
    bar.set_message %(Processing "foobar"...)
    bar.format = "[%bar%]\n%message%"

    bar.start
    bar.clear
    output.puts "Foo!"
    bar.display
    bar.finish

    self.assert_output(
      output,
      "[>---------------------------]\n",
      "Processing \"foobar\"...",
      "\x1B[1G\x1B[2K\x1B[1A",
      self.generate_output(""),
      "Foo!#{EOL}",
      self.generate_output("[--->------------------------]"),
      "\nProcessing \"foobar\"...",
      self.generate_output("[----->----------------------]\nProcessing \"foobar\"..."),
    )
  end

  def test_overwrite_with_section_output_and_eol : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.format = "[%bar%] %percent:3s%%#{EOL}%message%#{EOL}"
    bar.set_message ""
    bar.start
    bar.display
    bar.set_message "Doing something..."
    bar.advance
    bar.set_message "Doing something foo..."
    bar.advance

    self.assert_output(
      output,
      "[>---------------------------]   0%#{EOL}#{EOL}",
      "\x1b[2A\x1b[0J[>---------------------------]   2%#{EOL}Doing something...#{EOL}",
      "\x1b[2A\x1b[0J[=>--------------------------]   4%#{EOL}Doing something foo...#{EOL}",
    )
  end

  def test_overwrite_with_section_output_and_eol_with_empty_message : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.format = "[%bar%] %percent:3s%%#{EOL}%message%"
    bar.set_message "Start"
    bar.start
    bar.display
    bar.set_message ""
    bar.advance
    bar.set_message "Doing something..."
    bar.advance

    self.assert_output(
      output,
      "[>---------------------------]   0%#{EOL}Start#{EOL}",
      "\x1b[2A\x1b[0J[>---------------------------]   2%#{EOL}",
      "\x1b[1A\x1b[0J[=>--------------------------]   4%#{EOL}Doing something...#{EOL}",
    )
  end

  def test_overwrite_with_section_output_and_eol_with_empty_message_comment : Nil
    sections = Array(ACON::Output::Section).new
    acon_output = self.output

    output = ACON::Output::Section.new acon_output.io, sections, verbosity: acon_output.verbosity, decorated: acon_output.decorated?, formatter: ACON::Formatter::Output.new

    bar = ACON::Helper::ProgressBar.new output, 50, 0
    bar.format = "[%bar%] %percent:3s%%#{EOL}<comment>%message%</comment>"
    bar.set_message "Start"
    bar.start
    bar.display
    bar.set_message ""
    bar.advance
    bar.set_message "Doing something..."
    bar.advance

    self.assert_output(
      output,
      "[>---------------------------]   0%#{EOL}\x1b[33mStart\x1b[0m#{EOL}",
      "\x1b[2A\x1b[0J[>---------------------------]   2%#{EOL}",
      "\x1b[1A\x1b[0J[=>--------------------------]   4%#{EOL}\x1b[33mDoing something...\x1b[0m#{EOL}",
    )
  end

  private def generate_output(*expected : String) : String
    self.generate_output expected.join
  end

  private def generate_output(expected : String) : String
    count = expected.count '\n'

    sub_str = if count > 0
                "\e[1G\e[2K\e[1A" * count
              else
                ""
              end

    "#{sub_str}\e[1G\e[2K#{expected}"
  end

  private def output(decorated : Bool = true, verbosity : ACON::Output::Verbosity = :normal) : ACON::Output::Interface
    ACON::Output::IO.new IO::Memory.new, decorated: decorated, verbosity: verbosity
  end

  private def assert_output(output : ACON::Output::Interface, start : String, *frames : String, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    self.assert_output output, start, frames, line: line, file: file
  end

  private def assert_output(output : ACON::Output::Interface, start : String, frames : Enumerable(String) = [] of String, *, line : Int32 = __LINE__, file : String = __FILE__) : Nil
    expected = String.build do |io|
      io << start

      frames.join io
    end

    output.io.to_s.should eq(expected), line: line, file: file
  end
end
