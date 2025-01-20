require "../spec_helper"

struct NullStyleTest < ASPEC::TestCase
  def test_apply : Nil
    ACON::Formatter::NullStyle.new.apply("foo").should eq "foo"
  end

  def test_set_foreground : Nil
    style = ACON::Formatter::NullStyle.new
    style.foreground = :red
    style.apply("foo").should eq "foo"
  end

  def test_set_background : Nil
    style = ACON::Formatter::NullStyle.new
    style.background = :red
    style.apply("foo").should eq "foo"
  end

  def test_options : Nil
    style = ACON::Formatter::NullStyle.new

    style.add_option :bold
    style.apply("foo").should eq "foo"

    style.remove_option :bold
    style.apply("foo").should eq "foo"
  end
end
