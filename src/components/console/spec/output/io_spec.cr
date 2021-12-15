require "../spec_helper"

struct IOTest < ASPEC::TestCase
  @io : IO::Memory

  def initialize
    @io = IO::Memory.new
  end

  def tear_down : Nil
    @io.clear
  end

  def test_do_write : Nil
    output = ACON::Output::IO.new @io
    output.puts "foo"
    output.to_s.should eq "foo\n"
  end
end
