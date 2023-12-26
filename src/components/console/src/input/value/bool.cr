# :nodoc:
struct Athena::Console::Input::Value::Bool < Athena::Console::Input::Value
  getter value : ::Bool

  def initialize(@value : ::Bool); end

  def get(type : ::Bool.class) : ::Bool
    @value
  end

  def get(type : ::Bool?.class) : ::Bool?
    @value.try do |v|
      return v
    end

    nil
  end
end
