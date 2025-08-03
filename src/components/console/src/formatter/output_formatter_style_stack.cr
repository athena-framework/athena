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

    if match_index = @styles.rindex { |stacked_style| style.apply("") == stacked_style.apply("") }
      matched_style = @styles[match_index]

      @styles = @styles[0...match_index]

      return matched_style
    end

    raise ACON::Exception::InvalidArgument.new "Provided style is not present in the stack."
  end

  def current : ACON::Formatter::OutputStyleInterface
    @styles.last? || @empty_style
  end
end
