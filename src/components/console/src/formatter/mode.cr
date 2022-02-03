# TODO: Remove this type in favor in the stdlib's version when/if https://github.com/crystal-lang/crystal/pull/7690 is merged.
# TODO: Remove this monkey patch when Crystal 1.4.0 is released, and make it the min supported version
{% if compare_versions(Crystal::VERSION, "1.4.0-dev") >= 0 %}
  enum Colorize::Mode
    def to_sym
      self
    end
  end
{% end %}

@[Flags]
enum Athena::Console::Formatter::Mode
  # Makes the text bold.
  Bold = 1

  # Dims the text color.
  Dim

  # Underlines the text.
  Underline

  # Makes the text blink slowly.
  Blink

  # Swaps the foreground and background colors of the text.
  Reverse

  # Makes the text invisible.
  Hidden

  {% if compare_versions(Crystal::VERSION, "1.4.0-dev") >= 0 %}
    protected def to_sym : Colorize::Mode
      Colorize::Mode.parse self.to_s
    end
  {% else %}
    protected def to_sym : Symbol
      case self
      when .bold?      then :bold
      when .dim?       then :dim
      when .underline? then :underline
      when .blink?     then :blink
      when .reverse?   then :reverse
      when .hidden?    then :hidden
      else
        raise ""
      end
    end
  {% end %}
end
