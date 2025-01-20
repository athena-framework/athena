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
    output.print "bar"
    output.to_s.should eq "foo#{EOL}bar"
  end

  def test_do_write_var_args : Nil
    output = ACON::Output::IO.new @io
    output.puts "foo", "bar"
    output.print "biz", "baz"
    output.to_s.should eq "foo#{EOL}bar#{EOL}bizbaz"
  end

  def test_decorated_dumb_term : Nil
    with_isolated_env do
      ENV["TERM"] = "dumb"
      ACON::Output::IO.new(@io).decorated?.should be_false
    end
  end

  def test_decorated_no_color : Nil
    with_isolated_env do
      ENV["NO_COLOR"] = "true"
      ENV["COLORTERM"] = "truecolor"
      ACON::Output::IO.new(@io).decorated?.should be_false
    end
  end

  def test_decorated_no_color_empty : Nil
    with_isolated_env do
      ENV["NO_COLOR"] = ""
      ENV["COLORTERM"] = "truecolor"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_force_color : Nil
    with_isolated_env do
      ENV["FORCE_COLOR"] = "true"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_force_color_empty : Nil
    with_isolated_env do
      ENV["FORCE_COLOR"] = ""
      ACON::Output::IO.new(@io).decorated?.should be_false
    end
  end

  def test_decorated_supported_term : Nil
    with_isolated_env do
      ENV["TERM"] = "xterm-256color"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_colorterm : Nil
    with_isolated_env do
      ENV["COLORTERM"] = "truecolor"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_ansicon : Nil
    with_isolated_env do
      ENV["ANSICON"] = "1"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_conemuansi : Nil
    with_isolated_env do
      ENV["ConEmuANSI"] = "ON"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_term_program_hyper : Nil
    with_isolated_env do
      ENV["TERM_PROGRAM"] = "Hyper"
      ACON::Output::IO.new(@io).decorated?.should be_true
    end
  end

  def test_decorated_term_program_non_hyper : Nil
    with_isolated_env do
      ENV["TERM_PROGRAM"] = "WezTerm"
      ACON::Output::IO.new(@io).decorated?.should be_false
    end
  end
end
