# :nodoc:
struct Athena::Console::Input::Value::String < Athena::Console::Input::Value
  getter value : ::String

  def initialize(@value : ::String); end

  def get(type : ::Bool.class) : ::Bool
    raise ACON::Exception::Logic.new "'#{@value}' is not a valid 'Bool'." unless @value.in? "true", "false"

    @value == "true"
  end

  def get(type : ::Bool?.class) : ::Bool?
    (@value == "true").try do |v|
      raise ACON::Exception::Logic.new "'#{@value}' is not a valid 'Bool?'." unless @value.in? "true", "false"
      return v
    end

    nil
  end

  def get(type : ::Array(T).class) : ::Array(T) forall T
    Array.from_array(@value.split(',')).get ::Array(T)
  end

  def get(type : ::Array(T)?.class) : ::Array(T)? forall T
    Array.from_array(@value.split(',')).get ::Array(T)?
  end

  {% for type in ::Number::Primitive.union_types %}
    def get(type : {{type.id}}.class) : {{type.id}}
      {{type.id}}.new @value
    rescue ArgumentError
      raise ACON::Exception::Logic.new "'#{@value}' is not a valid '#{{{type.id}}}'."
    end

    def get(type : {{type.id}}?.class) : {{type.id}}?
      {{type.id}}.new(@value) || nil
    rescue ArgumentError
      raise ACON::Exception::Logic.new "'#{@value}' is not a valid '#{{{type.id}}}'."
    end
  {% end %}
end
