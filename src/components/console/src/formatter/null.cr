require "./interface"

# :nodoc:
class Athena::Console::Formatter::Null
  include Athena::Console::Formatter::Interface

  @style : ACON::Formatter::OutputStyle? = nil

  def decorated=(@decorated : Bool)
  end

  def decorated? : Bool
    false
  end

  def set_style(name : String, style : ACON::Formatter::OutputStyleInterface) : Nil
  end

  def has_style?(name : String) : Bool
    false
  end

  def style(name : String) : ACON::Formatter::OutputStyleInterface
    @style ||= ACON::Formatter::NullStyle.new
  end

  def format(message : String?) : String
    message
  end
end
