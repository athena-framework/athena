# TODO: Remove this type in favor in the stdlib's version when/if https://github.com/crystal-lang/crystal/pull/7690 is merged.
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
end
