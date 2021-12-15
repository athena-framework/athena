require "./wrappable_interface"

# Default implementation of `ACON::Formatter::WrappableInterface`.
class Athena::Console::Formatter::Output
  include Athena::Console::Formatter::WrappableInterface

  # Returns a new string where the special `<` characters in the provided *text* are escaped.
  def self.escape(text : String) : String
    text = text.gsub /([^\\\\]?)</, "\\1\\<"

    self.escape_trailing_backslash text
  end

  # Returns a new string where trailing `\` in the provided *text* is escaped.
  def self.escape_trailing_backslash(text : String) : String
    if text.ends_with? '\\'
      len = text.size
      text = text.rstrip '\\'
      text = text.gsub "\0", ""
      text += "\0" * (len - text.size)
    end

    text
  end

  # :nodoc:
  getter style_stack : ACON::Formatter::OutputStyleStack = ACON::Formatter::OutputStyleStack.new

  # :inherit:
  property? decorated : Bool

  @styles = Hash(String, ACON::Formatter::OutputStyleInterface).new
  @current_line_length = 0

  def initialize(@decorated : Bool = false, styles : ACON::Formatter::Mode? = nil)
    self.set_style "error", ACON::Formatter::OutputStyle.new(:white, :red)
    self.set_style "info", ACON::Formatter::OutputStyle.new(:green)
    self.set_style "comment", ACON::Formatter::OutputStyle.new(:yellow)
    self.set_style "question", ACON::Formatter::OutputStyle.new(:black, :cyan)
  end

  # :inherit:
  def set_style(name : String, style : ACON::Formatter::OutputStyleInterface) : Nil
    @styles[name.downcase] = style
  end

  # :inherit:
  def has_style?(name : String) : Bool
    @styles.has_key? name.downcase
  end

  # :inherit:
  def style(name : String) : ACON::Formatter::OutputStyleInterface
    @styles[name.downcase]
  end

  # :inherit:
  def format(message : String?) : String
    self.format_and_wrap message, 0
  end

  # :inherit:
  def format_and_wrap(message : String?, width : Int32) : String
    offset = 0
    output = ""

    @current_line_length = 0

    message.scan(/<(([a-z][^<>]*+) | \/([a-z][^<>]*+)?)>/ix) do |match|
      pos = match.begin.not_nil!
      text = match[0]

      next if pos != 0 && '\\' == message[pos - 1]

      # Add text up to next tag.
      output += self.apply_current_style message[offset, pos - offset], output, width
      offset = pos + text.size

      tag = if open = '/' != text.char_at(1)
              match[2]
            else
              match[3]? || ""
            end

      if !open && !tag.presence
        # </>
        @style_stack.pop
      elsif (style = self.create_style_from_string(tag)).nil?
        output += self.apply_current_style text, output, width
      elsif open
        @style_stack << style
      else
        @style_stack.pop style
      end
    end

    output += self.apply_current_style message[offset...], output, width

    if output.includes? '\0'
      return output
        .gsub("\0", '\\')
        .gsub("\\<", '<')
    end

    output.gsub /\\</, "<"
  end

  protected def create_style_from_string(string : String) : ACON::Formatter::OutputStyleInterface?
    if style = @styles[string]?
      return style
    end

    matches = string.scan /([^=]+)=([^;]+)(;|$)/

    return nil if matches.empty?

    style = ACON::Formatter::OutputStyle.new
    matches.each do |match|
      case match[1].downcase
      when "fg"   then style.foreground = match[2]
      when "bg"   then style.background = match[2]
      when "href" then style.href = match[2]
      when "options"
        match[2].downcase.scan /([^,;]+)/ do |option|
          style.add_option option[1]
        end
      else
        return nil
      end
    end

    style
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def apply_current_style(text : String, current : String, width : Int32)
    return "" if text.empty?

    if width.zero?
      return self.decorated? ? @style_stack.current.apply(text) : text
    end

    if @current_line_length.zero? && !current.empty?
      text = text.lstrip
    end

    if !@current_line_length.zero?
      i = width - @current_line_length
      prefix = "#{text[0, i]}\n"
      text = text[i...]? || ""
    else
      prefix = ""
    end

    # TODO: Something about matching `~(\\n)$~`.
    text = "#{prefix}#{text.gsub(/([^\\n]{#{width}})\ */, "\\1\n")}"
    text = text.chomp

    if @current_line_length.zero? && !current.empty? && !current.ends_with? "\n"
      text = "\n#{text}"
    end

    lines = text.split "\n"

    lines.each do |line|
      @current_line_length += line.size

      @current_line_length = 0 if width <= @current_line_length
    end

    if self.decorated?
      lines.map! do |line|
        @style_stack.current.apply line
      end
    end

    lines.join "\n"
  end
end
