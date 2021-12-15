# Defines an abstraction that format specific types, such as `JSON::Any`, or `YAML::Any` must implement.
module Athena::Serializer::Any
  abstract def as_bool : Bool
  abstract def as_i : Int32
  abstract def as_i? : Int32?
  abstract def as_f : Float64
  abstract def as_f? : Float64?
  abstract def as_f32 : Float32
  abstract def as_f32? : Float32?
  abstract def as_i64 : Int64
  abstract def as_i64? : Int64?
  abstract def as_s : String
  abstract def as_s? : String?
  abstract def as_a
  abstract def as_a?
  abstract def is_nil? : Bool
  abstract def dig(key_or_index : String | Int, *keys)

  abstract def raw
end

# :nodoc:
struct JSON::Any
  include Athena::Serializer::Any

  def is_nil? : Bool
    @raw.nil?
  end
end

# :nodoc:
struct YAML::Any
  include Athena::Serializer::Any

  def is_nil? : Bool
    @raw.nil?
  end
end
