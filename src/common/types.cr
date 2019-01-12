require "http/params"

# Converters for converting a `String` param into `T`.
module Athena::Types
  extend self

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
    String  => %(.gsub('"', "")),
  }

  {% for type, method in TYPES %}
    def convert_type(val : String, t : {{type.id}}.class) : {{type.id}}
      val{{method.id}}
    end

    def convert_type(val : String, t : Array({{type.id}})) : Array({{type.id}})
      val.split(',').map { |v| convert_type v, {{type.id}} }
    end
  {% end %}

  def convert_type(val : String, t : HTTP::Params.class) : HTTP::Params.class
    HTTP::Params.new val
  end
end
