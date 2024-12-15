require "../spec_helper"

struct NullSpec < ASPEC::TestCase
  def test_verbosity : Nil
    ACON::Output::Null.new.verbosity.silent?.should be_true
  end

  def test_formatter : Nil
    ACON::Output::Null.new.formatter.should be_a ACON::Formatter::Null
  end
end
