require "../spec_helper"

struct ProgressIndicatorTest < ASPEC::TestCase
  @clock : ACLK::Spec::MockClock

  def initialize
    @clock = ACLK::Spec::MockClock.new
  end

  def test_set_placeholder_formatter : Nil
    ACON::Helper::ProgressIndicator.set_placeholder_formatter "custom-message" do
      # Return any arbitrary string
      "My Custom Message"
    end

    ACON::Helper::ProgressIndicator
      .placeholder_formatter("custom-message")
      .try(&.call(ACON::Helper::ProgressIndicator.new self.output(decorated: false)))
      .should eq "My Custom Message"
  end

  def test_default_indicator : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output, clock: @clock

    indicator.start "Starting..."
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.message = "Advancing..."
    indicator.advance
    indicator.finish "Done..."
    indicator.start "Starting Again..."
    @clock.sleep 101.milliseconds
    indicator.advance
    indicator.finish "Done Again..."

    self.assert_output(
      output,
      self.generate_output(" - Starting..."),
      self.generate_output(" \\ Starting..."),
      self.generate_output(" | Starting..."),
      self.generate_output(" / Starting..."),
      self.generate_output(" - Starting..."),
      self.generate_output(" \\ Starting..."),
      self.generate_output(" \\ Advancing..."),
      self.generate_output(" | Advancing..."),
      self.generate_output(" ✔ Done..."),
      EOL,
      self.generate_output(" - Starting Again..."),
      self.generate_output(" \\ Starting Again..."),
      self.generate_output(" ✔ Done Again..."),
      EOL,
    )
  end

  def test_non_decorated : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output(decorated: false)

    indicator.start "Starting..."
    indicator.advance
    indicator.advance
    indicator.message = "Midway..."
    indicator.advance
    indicator.advance
    indicator.finish "Done..."

    self.assert_output(
      output,
      " Starting...#{EOL}",
      " Midway...#{EOL}",
      " Done...#{EOL}#{EOL}",
    )
  end

  def test_custom_indicator_values : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output, indicator_values: %w(a b c), clock: @clock

    indicator.start "Starting..."
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance
    @clock.sleep 101.milliseconds
    indicator.advance

    self.assert_output(
      output,
      self.generate_output(" a Starting..."),
      self.generate_output(" b Starting..."),
      self.generate_output(" c Starting..."),
      self.generate_output(" a Starting..."),
    )
  end

  def test_custom_finished_indicator_value : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output, finished_indicator: "✅", clock: @clock

    indicator.start "Starting..."
    @clock.sleep 101.milliseconds
    indicator.finish "Done"

    self.assert_output(
      output,
      self.generate_output(" - Starting..."),
      self.generate_output(" ✅ Done"),
      EOL
    )
  end

  def test_custom_finished_indicator_value_finish : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output, clock: @clock

    indicator.start "Starting..."
    @clock.sleep 101.milliseconds
    indicator.finish "Done", "|==|"

    self.assert_output(
      output,
      self.generate_output(" - Starting..."),
      self.generate_output(" |==| Done"),
      EOL
    )
  end

  def test_requires_at_least_two_indicator_characters : Nil
    expect_raises ACON::Exception::InvalidArgument, "Must have at least 2 indicator value characters." do
      ACON::Helper::ProgressIndicator.new self.output, indicator_values: %w(a)
    end
  end

  def test_cannot_start_already_started_indicator : Nil
    indicator = ACON::Helper::ProgressIndicator.new self.output
    indicator.start "Starting..."

    expect_raises ACON::Exception::Logic, "Progress indicator is already started." do
      indicator.start "Starting Again..."
    end
  end

  def test_cannot_advance_unstarted_indicator : Nil
    indicator = ACON::Helper::ProgressIndicator.new self.output

    expect_raises ACON::Exception::Logic, "Progress indicator has not yet been started." do
      indicator.advance
    end
  end

  def test_cannot_finish_unstarted_indicator : Nil
    indicator = ACON::Helper::ProgressIndicator.new self.output

    expect_raises ACON::Exception::Logic, "Progress indicator has not yet been started." do
      indicator.finish "Finishing..."
    end
  end

  @[TestWith(
    {ACON::Helper::ProgressIndicator::Format::DEBUG},
    {ACON::Helper::ProgressIndicator::Format::VERY_VERBOSE},
    {ACON::Helper::ProgressIndicator::Format::VERBOSE},
    {ACON::Helper::ProgressIndicator::Format::NORMAL},
  )]
  def test_formats(format : ACON::Helper::ProgressIndicator::Format) : Nil
    indicator = ACON::Helper::ProgressIndicator.new output = self.output, format: format
    indicator.start "Starting..."
    indicator.advance

    output.io.to_s.should_not be_empty
  end

  private def generate_output(expected : String) : String
    count = expected.count '\n'

    sub_str = if count > 0
                "\033[#{count}A"
              else
                ""
              end

    "\x0D\x1B[2K#{sub_str}#{expected}"
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
