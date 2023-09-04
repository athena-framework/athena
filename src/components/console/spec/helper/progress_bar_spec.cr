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

    output.io.to_s.should eq %(    0 [>---------------------------]#{self.generate_output "    1 [->--------------------------]"}#{self.generate_output "    0 [>---------------------------]"})
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
end
