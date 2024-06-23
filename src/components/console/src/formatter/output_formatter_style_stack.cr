# :nodoc:
struct Athena::Console::Formatter::OutputStyleStack
  property empty_style : ACON::Formatter::OutputStyleInterface

  @styles = Array(ACON::Formatter::OutputStyleInterface).new

  def initialize(@empty_style : ACON::Formatter::OutputStyleInterface = ACON::Formatter::OutputStyle.new)
    self.reset
  end

  def reset : Nil
    @styles.clear
  end

  def <<(style : ACON::Formatter::OutputStyleInterface) : Nil
    @styles << style
  end

  def pop(style : ACON::Formatter::OutputStyleInterface? = nil) : ACON::Formatter::OutputStyleInterface
    return @empty_style if @styles.empty?

    return @styles.pop if style.nil?

    @styles.reverse_each.each_with_index do |stacked_style, idx|
      if style.apply("") == stacked_style.apply("")
        @styles = @styles[0...idx]

        return stacked_style
      end
    end

    raise ACON::Exception::InvalidArgument.new "Provided style is not present in the stack."
  end

  def current : ACON::Formatter::OutputStyleInterface
    @styles.last? || @empty_style
  end
end
