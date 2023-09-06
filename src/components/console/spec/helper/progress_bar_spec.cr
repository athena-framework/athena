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
      " \033[44;37m 0/50\033[0m [>---------------------------]   0%#{ACON::System::EOL}",
      "\e[1A\e[0J \033[44;37m 1/50\033[0m [>---------------------------]   2%#{ACON::System::EOL}",
      "\e[1A\e[0J \033[44;37m 2/50\033[0m [=>--------------------------]   4%#{ACON::System::EOL}",
      raw: true
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
      "  0/50 [>---------------------------]   0%#{ACON::System::EOL}",
      "  0/50 [>---------------------------]   0%#{ACON::System::EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      "\e[2A\e[0J  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      "\e[1A\e[0J  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      "  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      raw: true
    )
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
      raw: true
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
      " 0/50 [>---------------------------]   0% %message% EXISTING TEXT.#{ACON::System::EOL}",
      "\e[1A\e[0J 1/50 [>---------------------------]   2% MESSAGE\nTEXT! EXISTING TEXT.#{ACON::System::EOL}",
      "\e[2A\e[0J 2/50 [=>--------------------------]   4% OTHER\nTEXT! EXISTING TEXT.#{ACON::System::EOL}",
      raw: true
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
      "  0/50 [>---------------------------]   0%#{ACON::System::EOL}",
      " 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{ACON::System::EOL}",
      "\e[4A\e[0J 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{ACON::System::EOL}",
      "\e[3A\e[0J  1/50 [>---------------------------]   2%#{ACON::System::EOL}",
      " 0/50 [>]   0% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{ACON::System::EOL}",
      "\e[3A\e[0J 1/50 [>]   2% Fruitcake marzipan toffee. Cupcake gummi bears tart dessert ice cream chupa chups cupcake chocolate bar sesame snaps. Croissant halvah cookie jujubes powder macaroon. Fruitcake bear claw bonbon jelly beans oat cake pie muffin Fruitcake marzipan toffee.#{ACON::System::EOL}",
      raw: true
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
      " 1/50 [>---------------------------]",
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
      "  1/50 [>---------------------------]   2%",
      " 15/50 [========>-------------------]  30%",
      " 25/50 [==============>-------------]  50%",
    )
  end

  def test_set_current_progress_before_start : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, minimum_seconds_between_redraws: 0
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
      " 3/6 [==============>-------------]  50%",
      " 5/6 [=======================>----]  83%",
      " 6/6 [============================] 100%",
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
      "    1 [->--------------------------]",
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
      "    1 [->--------------------------]",
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
      "    3 [■■■>------------------------]",
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
      " 25/50 [==============>-------------]  50%",
      ""
    )
  end

  def test_percent_not_hundread_before_complete : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 200, 0
    bar.start
    bar.display
    bar.advance 199
    bar.advance

    self.assert_output(
      output,
      "   0/200 [>---------------------------]   0%",
      " 199/200 [===========================>]  99%",
      " 200/200 [============================] 100%"
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
      "   0/200 [>---------------------------]   0%#{ACON::System::EOL}",
      "  20/200 [==>-------------------------]  10%#{ACON::System::EOL}",
      "  40/200 [=====>----------------------]  20%#{ACON::System::EOL}",
      "  60/200 [========>-------------------]  30%#{ACON::System::EOL}",
      "  80/200 [===========>----------------]  40%#{ACON::System::EOL}",
      " 100/200 [==============>-------------]  50%#{ACON::System::EOL}",
      " 120/200 [================>-----------]  60%#{ACON::System::EOL}",
      " 140/200 [===================>--------]  70%#{ACON::System::EOL}",
      " 160/200 [======================>-----]  80%#{ACON::System::EOL}",
      " 180/200 [=========================>--]  90%#{ACON::System::EOL}",
      " 200/200 [============================] 100%",
      raw: true
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
      "  0/50 [>---------------------------]   0%#{ACON::System::EOL}",
      " 25/50 [==============>-------------]  50%#{ACON::System::EOL}",
      " 50/50 [============================] 100%",
      raw: true
    )
  end

  def test_non_decorated_output_without_max : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output(decorated: false), minimum_seconds_between_redraws: 0
    bar.start
    bar.advance

    self.assert_output(
      output,
      "    0 [>---------------------------]#{ACON::System::EOL}",
      "    1 [->--------------------------]",
      raw: true
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
      "\e[2A\e[1G\e[2K 1/2 [==============>-------------]  50%\n",
      "\e[1G\e[2K 1/3 [=========#------------------]  33%\n",
      "\e[1G\e[2K    1 [->--------------------------]",
      "\e[2A\e[1G\e[2K 2/2 [============================] 100%\n",
      "\e[1G\e[2K 2/3 [==================#---------]  66%\n",
      "\e[1G\e[2K    2 [-->-------------------------]\e[2A\n",
      "\e[1G\e[2K 3/3 [============================] 100%\n",
      "\e[1G\e[2K    3 [--->------------------------]\e[2A\n",
      "\n",
      "\e[1G\e[2K    3 [============================]",
      raw: true
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
      "    1 [->--------------------------]",
      "    2 [-->-------------------------]",
      "    3 [--->------------------------]",
      "    3 [============================]",
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
      "    2 [-->-------------------------]",
      "  5/10 [==============>-------------]  50%",
      "  10/100 [==>-------------------------]  10%",
      " 100/100 [============================] 100%",
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
      "    1 [->--]",
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
      " 2 [=========>------------------]",
      " 0 [============================]",
    )
  end

  def test_adding_instance_placeholder_formatter : Nil
    bar = ACON::Helper::ProgressBar.new output = self.output, 3, 0
    bar.format = " %countdown% [%bar%]"
    bar.set_placeholder_formatter "countdown" do |bar|
      "#{bar.max_steps - bar.progress}"
    end

    bar.start
    bar.advance
    bar.finish

    self.assert_output(
      output,
      " 3 [>---------------------------]",
      " 2 [=========>------------------]",
      " 0 [============================]",
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

    "#{sub_str}\e[1G\e[2K#{expected}"
  end

  private def output(decorated : Bool = true, verbosity : ACON::Output::Verbosity = :normal) : ACON::Output::Interface
    ACON::Output::IO.new IO::Memory.new, decorated: decorated, verbosity: verbosity
  end

  private def assert_output(output : ACON::Output::Interface, start : String, *frames : String, raw : Bool = false) : Nil
    self.assert_output output, start, frames, raw: raw
  end

  private def assert_output(output : ACON::Output::Interface, start : String, frames : Enumerable(String) = [] of String, *, raw : Bool = false) : Nil
    expected = String.build do |io|
      io << start

      # frames.join io
      frames.each do |frame|
        io << (raw ? frame : self.generate_output(frame))
      end
    end

    output.io.to_s.should eq expected
  end
end
