require "../spec_helper"

describe ACON::Formatter::OutputStyleStack do
  it "#<<" do
    stack = ACON::Formatter::OutputStyleStack.new
    stack << ACON::Formatter::OutputStyle.new :white, :black
    stack << (s2 = ACON::Formatter::OutputStyle.new :yellow, :blue)

    stack.current.should eq s2

    stack << (s3 = ACON::Formatter::OutputStyle.new :green, :red)

    stack.current.should eq s3
  end

  describe "#pop" do
    it "returns the oldest style" do
      stack = ACON::Formatter::OutputStyleStack.new
      stack << (s1 = ACON::Formatter::OutputStyle.new :white, :black)
      stack << (s2 = ACON::Formatter::OutputStyle.new :yellow, :blue)

      stack.pop.should eq s2
      stack.pop.should eq s1
    end

    it "returns the default style if empty" do
      stack = ACON::Formatter::OutputStyleStack.new
      style = ACON::Formatter::OutputStyle.new

      stack.pop.should eq style
    end

    it "allows popping a specific style" do
      stack = ACON::Formatter::OutputStyleStack.new
      stack << (s1 = ACON::Formatter::OutputStyle.new :white, :black)
      stack << (s2 = ACON::Formatter::OutputStyle.new :yellow, :blue)
      stack << ACON::Formatter::OutputStyle.new :green, :red

      stack.pop(s2).should eq s2
      stack.pop.should eq s1
    end

    it "invalid pop" do
      stack = ACON::Formatter::OutputStyleStack.new
      stack << ACON::Formatter::OutputStyle.new :white, :black

      expect_raises ACON::Exceptions::InvalidArgument, "Provided style is not present in the stack." do
        stack.pop ACON::Formatter::OutputStyle.new :yellow, :blue
      end
    end
  end
end
