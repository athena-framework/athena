# Converters for converting a `String` param into `T`.
module Athena::Types
  extend self

  def convert_type(val : String, t : Int8.class) : Int8
    val.to_i8
  end

  def convert_type(val : String, t : Int16.class) : Int16
    val.to_i16
  end

  def convert_type(val : String, t : Int32.class) : Int32
    val.to_i
  end

  def convert_type(val : String, t : Int64.class) : Int64
    val.to_i64
  end

  def convert_type(val : String, t : UInt8.class) : UInt8
    val.to_u8
  end

  def convert_type(val : String, t : UInt16.class) : UInt16
    val.to_u16
  end

  def convert_type(val : String, t : UInt32.class) : UInt32
    val.to_u32
  end

  def convert_type(val : String, t : UInt64.class) : UInt64
    val.to_u64
  end

  def convert_type(val : String, t : Float32.class) : Float32
    val.to_f32
  end

  def convert_type(val : String, t : Float64.class) : Float64
    val.to_f
  end

  def convert_type(val : String, t : Bool.class) : Bool
    val == "true"
  end

  def convert_type(val : String, t : String.class) : String
    val.gsub('"', "")
  end
end
