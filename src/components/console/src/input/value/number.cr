# :nodoc:
struct Athena::Console::Input::Value::Number < Athena::Console::Input::Value
  getter value : ::Number::Primitive

  def initialize(@value : ::Number::Primitive); end

  {% for type in ::Number::Primitive.union_types %}
    def get(type : {{type.id}}.class) : {{type.id}}
      {{type.id}}.new @value
    end

    def get(type : {{type.id}}?.class) : {{type.id}}?
      {{type.id}}.new(@value) || nil
    end
  {% end %}
end
