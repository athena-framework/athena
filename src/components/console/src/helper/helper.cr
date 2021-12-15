require "./interface"

# Contains `ACON::Helper::Interface` implementations that can be used to help with various tasks.
# Such as asking questions, or customizing the output format.
#
# This class also acts as a base type that implements common functionality between each helper.
abstract class Athena::Console::Helper
  include Athena::Console::Helper::Interface

  # Returns a new string with all of its ANSI formatting removed.
  def self.remove_decoration(formatter : ACON::Formatter::Interface, string : String) : String
    is_decorated = formatter.decorated?
    formatter.decorated = false
    string = formatter.format string
    string = string.gsub /\033\[[^m]*m/, ""
    formatter.decorated = is_decorated

    string
  end

  # Returns the width of a string; where the width is how many character positions the string will use.
  #
  # TODO: Support double width chars.
  def self.width(string : String) : Int32
    string.size
  end

  property helper_set : ACON::Helper::HelperSet? = nil
end
