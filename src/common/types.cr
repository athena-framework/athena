# Converters for converting `String` arguments into `T`.
module Athena::Types
  extend self

  # :nodoc:
  TYPES = {
    Int8    => ".to_i8",
    Int16   => ".to_i16",
    Int32   => ".to_i",
    Int64   => ".to_i64",
    UInt8   => ".to_u8",
    UInt16  => ".to_u16",
    UInt32  => ".to_u32",
    UInt64  => ".to_u64",
    Float32 => ".to_f32",
    Float64 => ".to_f",
    Bool    => %( == "true"),
    String  => %(), # Leave strings as is
  }

  {% for type, method in TYPES %}
    # Converts a `String` to `{{type}}`.
    def convert_type(val : String, t : {{type.id}}.class) : {{type.id}}
      val{{method.id}}
    end

    # Converts a `String` to `{{type}}?`.
    def convert_type(val : String, t : {{type.id}}?.class) : {{type.id}}?
      val{{method.id}}
    end

    # Converts an `Array(String)` to `Array({{type.id}})`.
    def convert_type(val : String, t : Array({{type.id}}).class) : Array({{type.id}})
      val.split(',').map { |v| convert_type v, {{type.id}} }
    end

    # Converts an `Array(String)` to `Array({{type.id}})?`.
    def convert_type(val : String, t : Array({{type.id}})?.class) : Array({{type.id}})?
      val.split(',').map { |v| convert_type v, {{type.id}} }
    end
  {% end %}

  def convert_type(val : String, t)
    val
  end
end
