# An `ACON::Input::Interface` based on [ARGV](https://crystal-lang.org/api/toplevel.html#ARGV).
class Athena::Console::Input::ARGV < Athena::Console::Input
  @tokens : Array(String)
  @parsed : Array(String) = [] of String

  def self.new(*tokens : String)
    new tokens.to_a
  end

  def initialize(@tokens : Array(String) = ::ARGV, definition : ACON::Input::Definition? = nil)
    super definition
  end

  # :inherit:
  # ameba:disable Metrics/CyclomaticComplexity
  def first_argument : String?
    is_option = false

    @tokens.each_with_index do |token, idx|
      if !token.empty? && token.starts_with? '-'
        next if token.includes?('=') || @tokens[idx + 1]?.nil?

        name = '-' == token.char_at(1) ? token[2..] : token[-1..]

        if !@options.has_key?(name) && !@definition.has_shortcut?(name)
          # noop
        elsif (@options.has_key?(name) || @options.has_key?(name = @definition.shortcut_to_name(name))) && @tokens[idx + 1]? == @options[name].value
          is_option = true
        end

        next
      end

      if is_option
        is_option = false
        next
      end

      return token
    end

    nil
  end

  # :inherit:
  def has_parameter?(*values : String, only_params : Bool = false) : Bool
    @tokens.each do |token|
      return false if only_params && "--" == token

      values.each do |value|
        leading = value.starts_with?("--") ? "#{value}=" : value
        return true if token == value || (!leading.empty? && token.starts_with? leading)
      end
    end

    false
  end

  # :inherit:
  def parameter(value : String, default : _ = false, only_params : Bool = false)
    tokens = @tokens.dup

    while token = tokens.shift?
      return default if only_params && "--" == token
      return tokens.shift? if token == value

      leading = value.starts_with?("--") ? "#{value}=" : value
      return token[leading.size..] if !leading.empty? && token.starts_with? leading
    end

    default
  end

  # :inherit:
  def to_s(io : IO) : Nil
    @tokens.join io, " " do |token, join_io|
      if match = token.match /^(-[^=]+=)(.+)/
        join_io << match[1]
        join_io << self.escape_token match[2]
        next
      end

      if !token.empty? && '-' != token[0]
        join_io << self.escape_token token
        next
      end

      join_io << token
    end
  end

  protected def parse : Nil
    parse_options = true
    @parsed = @tokens.dup

    while token = @parsed.shift?
      parse_options = self.parse_token token, parse_options
    end
  end

  protected def parse_token(token : String, parse_options : Bool) : Bool
    if parse_options && token.empty?
      self.parse_argument token
    elsif parse_options && "--" == token
      return false
    elsif parse_options && token.starts_with? "--"
      self.parse_long_option token
    elsif parse_options && token.starts_with?('-') && "-" != token
      self.parse_short_option token
    else
      self.parse_argument token
    end

    parse_options
  end

  private def parse_argument(token : String) : Nil
    count = @arguments.size

    # If expecting another argument, add it.
    if @definition.has_argument? count
      argument = @definition.argument count
      @arguments[argument.name] = argument.is_array? ? ACON::Input::Value::Array.new(token) : ACON::Input::Value.from_value token

      # If the last argument IS_ARRAY, append token to last argument.
    elsif @definition.has_argument?(count - 1) && @definition.argument(count - 1).is_array?
      argument = @definition.argument(count - 1)
      @arguments[argument.name].as(ACON::Input::Value::Array) << token

      # TODO: Handle unexpected argument.
    else
    end
  end

  private def parse_long_option(token : String) : Nil
    name = token.lchop "--"

    if pos = name.index '='
      if (value = name[(pos + 1)..]).empty?
        @parsed.unshift value
      end

      self.add_long_option name[0, pos], value
    else
      self.add_long_option name, nil
    end
  end

  # ameba:disable Metrics/CyclomaticComplexity
  private def add_long_option(name : String, value : String?) : Nil
    unless @definition.has_option?(name)
      raise ACON::Exceptions::InvalidOption.new "The '--#{name}' option does not exist." unless @definition.has_negation? name

      option_name = @definition.negation_to_name name
      raise ACON::Exceptions::InvalidOption.new "The '--#{name}' option does not accept a value." unless value.nil?

      return @options[option_name] = ACON::Input::Value.from_value false
    end

    option = @definition.option name

    if !value.nil? && !option.accepts_value?
      raise ACON::Exceptions::InvalidOption.new "The --#{option.name} option does not accept a value."
    end

    if value.in?("", nil) && option.accepts_value? && !@parsed.empty?
      next_value = @parsed.shift?

      if ((v = next_value.presence) && '-' != v.char_at(0)) || next_value.in?("", nil)
        value = next_value
      else
        @parsed.unshift next_value || ""
      end
    end

    if value.nil?
      raise ACON::Exceptions::InvalidOption.new "The --#{option.name} option requires a value." if option.value_required?
      value = true if !option.is_array? && !option.value_optional?
    end

    if option.is_array?
      (@options[name] ||= ACON::Input::Value::Array.new).as(ACON::Input::Value::Array) << value
    else
      @options[name] = ACON::Input::Value.from_value value
    end
  end

  private def parse_short_option(token : String) : Nil
    name = token.lchop '-'

    if name.size > 1
      if @definition.has_shortcut?(name[0]) && @definition.option_for_shortcut(name[0]).accepts_value?
        # Option with a value & no space
        self.add_short_option name[0], name[1..]
      else
        self.parse_short_option_set name
      end
    else
      self.add_short_option name, nil
    end
  end

  private def parse_short_option_set(name : String) : Nil
    length = name.size
    name.each_char_with_index do |char, idx|
      raise ACON::Exceptions::InvalidOption.new "The -#{char} option does not exist." unless @definition.has_shortcut? char

      option = @definition.option_for_shortcut char

      if option.accepts_value?
        self.add_long_option option.name, idx == length - 1 ? nil : name[(idx + 1)..]

        break
      else
        self.add_long_option option.name, nil
      end
    end
  end

  private def add_short_option(name : String | Char, value : String?) : Nil
    name = name.to_s

    raise ACON::Exceptions::InvalidOption.new "The -#{name} option does not exist." if !@definition.has_shortcut? name

    self.add_long_option @definition.option_for_shortcut(name).name, value
  end
end
