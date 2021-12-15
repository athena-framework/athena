require "./spec_helper"

struct TerminalTest < ASPEC::TestCase
  @col_size : Int32?
  @line_size : Int32?

  def initialize
    @col_size = ENV["COLUMNS"]?.try &.to_i?
    @line_size = ENV["LINES"]?.try &.to_i?
  end

  def tear_down : Nil
    ENV.delete "COLUMNS"
    ENV.delete "LINES"
  end

  def test_height_width : Nil
    ENV["COLUMNS"] = "100"
    ENV["LINES"] = "50"

    terminal = ACON::Terminal.new
    terminal.width.should eq 100
    terminal.height.should eq 50

    ENV["COLUMNS"] = "120"
    ENV["LINES"] = "60"

    terminal = ACON::Terminal.new
    terminal.width.should eq 120
    terminal.height.should eq 60
  end

  def test_zero_values : Nil
    ENV["COLUMNS"] = "0"
    ENV["LINES"] = "0"

    terminal = ACON::Terminal.new
    terminal.width.should eq 0
    terminal.height.should eq 0
  end
end
