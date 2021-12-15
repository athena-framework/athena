# :nodoc:
abstract struct Athena::Console::Input::Value
  def self.from_value(value : T) : self forall T
    case value
    when ACON::Input::Value then value
    when ::Nil              then ACON::Input::Value::Nil.new
    when ::String           then ACON::Input::Value::String.new value
    when ::Number           then ACON::Input::Value::Number.new value
    when ::Bool             then ACON::Input::Value::Bool.new value
    when ::Array            then ACON::Input::Value::Array.from_array value
    else
      raise "Unsupported type: #{T}."
    end
  end

  def get(type : ::String.class) : ::String
    self.to_s
  end

  def get(type : ::String?.class) : ::String?
    self.to_s.presence
  end

  def get(type : T.class) : NoReturn forall T
    raise ACON::Exceptions::Logic.new "'#{self.value}' is not a valid '#{T}'."
  end

  def to_s(io : IO) : ::Nil
    self.value.to_s io
  end

  abstract def value
end
