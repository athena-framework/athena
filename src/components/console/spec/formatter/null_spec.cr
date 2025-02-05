require "../spec_helper"

struct NullFormatterTest < ASPEC::TestCase
  def test_has_style : Nil
    ACON::Formatter::Null.new.has_style?("error").should be_false
  end

  def test_style : Nil
    ACON::Formatter::Null.new.style("error").should be_a ACON::Formatter::NullStyle
  end
end
