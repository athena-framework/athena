require "../spec_helper"

struct NullSpec < ASPEC::TestCase
  def test_verbosity : Nil
    ACON::Output::Null.new.verbosity.silent?.should be_true
  end

  def test_formatter : Nil
    output = ACON::Output::Null.new
    output.formatter.should be_a ACON::Formatter::Null
    output.formatter = ACON::Formatter::Output.new
    output.formatter.should be_a ACON::Formatter::Null
  end
end
