# require "semantic_version"
# require "uuid"

# require "json"
# require "yaml"

# require "athena-dependency_injection"

# require "./annotations"
# require "./any"
# require "./context"
# require "./serializable"
# require "./serializer_interface"
# require "./serializer"
# require "./property_metadata"
# require "./deserialization_context"
# require "./serialization_context"

# require "./construction/*"
# require "./exception/*"
# require "./exclusion_strategies/*"
# require "./navigators/*"
# require "./visitors/*"

# # Convenience alias to make referencing `Athena::Serializer` types easier.
# alias ASR = Athena::Serializer

# # Convenience alias to make referencing `Athena::Serializer::Annotations` types easier.
# alias ASRA = Athena::Serializer::Annotations

# # :nodoc:
# module JSON; end

# # :nodoc:
# module YAML; end

# # Provides enhanced (de)serialization features.
# module Athena::Serializer
#   VERSION = "0.3.6"

#   # Returns an `ASR::SerializerInterface` instance for ad-hoc (de)serialization.
#   #
#   # The serializer is cached and only instantiated once.
#   class_getter serializer : ASR::SerializerInterface { ASR::Serializer.new }

#   # The built-in supported formats.
#   enum Format
#     JSON
#     YAML

#     # Returns the `ASR::Visitors::SerializationVisitorInterface` related to `self`.
#     def serialization_visitor
#       case self
#       in .json? then ASR::Visitors::JSONSerializationVisitor
#       in .yaml? then ASR::Visitors::YAMLSerializationVisitor
#       end
#     end

#     # Returns the `ASR::Visitors::DeserializationVisitorInterface` related to `self`.
#     def deserialization_visitor
#       case self
#       in .json? then ASR::Visitors::JSONDeserializationVisitor
#       in .yaml? then ASR::Visitors::YAMLDeserializationVisitor
#       end
#     end
#   end

#   # Contains all custom exceptions defined within `Athena::Serializer`.
#   # Also acts as a marker that can be used to rescue all serializer related exceptions.
#   module Exception; end

#   # Exclusion Strategies allow controlling which properties should be (de)serialized.
#   #
#   # `Athena::Serializer` includes two common strategies: `ASR::ExclusionStrategies::Groups`, and `ASR::ExclusionStrategies::Version`.
#   #
#   # Custom strategies can be implemented by via `ExclusionStrategies::ExclusionStrategyInterface`.
#   #
#   # !!!todo
#   #     Once feasible, support compile time exclusion strategies.
#   module ExclusionStrategies; end

#   # Used to denote a type that is (de)serializable.
#   #
#   # This module can be used to make the compiler happy in some situations, it doesn't do anything on its own.
#   # You most likely want to use `ASR::Serializable` instead.
#   #
#   # ```
#   # require "athena-serializer"
#   #
#   # abstract struct BaseModel
#   #   # `ASR::Model` is needed here to ensure typings are correct for the deserialization process.
#   #   # Child types should still include `ASR::Serializable`.
#   #   include ASR::Model
#   # end
#   #
#   # record ModelOne < BaseModel, id : Int32, name : String do
#   #   include ASR::Serializable
#   # end
#   #
#   # record ModelTwo < BaseModel, id : Int32, name : String do
#   #   include ASR::Serializable
#   # end
#   #
#   # record Unionable, type : BaseModel.class
#   # ```
#   module Model; end
# end

require "json"

struct SerializedAny
  alias Type = Nil | Bool | Int64 | Float64 | String | Array(SerializedAny) | Hash(SerializedAny, SerializedAny)

  # :nodoc:
  def self.new(raw : JSON::Any) : self
    self.from_value raw.raw
  end

  def self.from_value(value : _) : self
    new(
      case value
      when Hash
        value.each_with_object({} of self => self) do |(k, v), hash|
          key = k.is_a?(self) ? k : SerializedAny.new(k)
          value = v.is_a?(self) ? v : SerializedAny.new(v)

          hash[key] = value
        end
      when Enumerable
        value.map do |v|
          v.is_a?(self) ? v : SerializedAny.new(v)
        end
      else
        value
      end
    )
  end

  # Returns the raw underlying value.
  getter raw : Type

  def initialize(@raw : Type); end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index.
  # Raises if the underlying value is not an `Array`.
  def [](key_or_index : _) : JSON::Any
    case object = @raw
    when Array, Hash
      object[index]
    else
      raise "Expected Array or Hash for #[](index : key_or_index), not #{object.class}"
    end
  end

  # Assumes the underlying value is an `Array` and returns the element
  # at the given index, or `nil` if out of bounds.
  # Raises if the underlying value is not an `Array`.
  def []?(key_or_index : _) : JSON::Any?
    case object = @raw
    when Array, Hash
      object[index]?
    else
      raise "Expected Array or Hash for #[]?(index : Int), not #{object.class}"
    end
  end
end

module SerializerInterface
  abstract def serialize(data : _, format : String, context = nil) : String

  abstract def deserialize(data : _, type : T, format : String, context = nil) : T forall T
end

module NormalizerInterface
  abstract def normalize(data : _, format : String? = nil, context = nil)
  abstract def supports_normalization?(data : _, format : String? = nil, context = nil) : Bool
end

module DenormalizerInterface
  abstract def denormalize(data : _, type : T, format : String? = nil, context = nil) : T forall T
  abstract def supports_denormalization?(data : _, type : T, format : String? = nil, context = nil) : Bool forall T
end

module DecoderInterface
  abstract def decode(data : _, format : String, context = nil) : SerializedAny
  abstract def supports_decoding?(format : String, context = nil) : Bool
end

class ChainDecoder
  include DecoderInterface

  @decoders_by_format = Hash(String, Int32).new

  def initialize(@decoders : Array(DecoderInterface))
  end

  def decode(data : _, format : String, context = nil) : SerializedAny
    self.decoder(format, context).decode data, format, context
  end

  def supports_decoding?(format : String, context = nil) : Bool
    !!self.decoder(format, context) rescue false
  end

  private def decoder(format : String, context) : DecoderInterface
    if (idx = @decoders_by_format[format]?) && !@decoders.index(idx).nil?
      return @decoders[idx]
    end

    cache = true

    @decoders.each_with_index do |decoder, idx|
      cache = cache && false

      if decoder.supports_decoding?(format, context)
        @decoders_by_format[format] = idx if cache

        return decoder
      end
    end

    raise "No decoder found for #{format}."
  end
end

module EncoderInterface
  abstract def encode(data : SerializedAny, format : String, context = nil) : String
  abstract def supports_encoding?(format : String, context = nil) : Bool
end

class ChainEncoder
  include EncoderInterface

  @encoders_by_format = Hash(String, Int32).new

  def initialize(@encoders : Array(EncoderInterface))
  end

  def encode(data : _, format : String, context = nil) : String
    self.encoder(format, context).encode data, format, context
  end

  def supports_encoding?(format : String, context = nil) : Bool
    !!self.encoder(format, context) rescue false
  end

  private def encoder(format : String, context) : EncoderInterface
    if (idx = @encoders_by_format[format]?) && !@encoders.index(idx).nil?
      return @encoders[idx]
    end

    cache = true

    @encoders.each_with_index do |encoder, idx|
      cache = cache && false

      if encoder.supports_encoding?(format, context)
        @encoders_by_format[format] = idx if cache

        return encoder
      end
    end

    raise "No encoder found for #{format}."
  end
end

class JSONEncoder
  include DecoderInterface
  include EncoderInterface

  def decode(data : _, format : String, context = nil)
    JSON.parse data
  end

  def supports_decoding?(format : String) : Bool
    "json" == format
  end

  def encode(data : SerializedAny, format : String, context = nil) : String
    data.to_json
  end

  def supports_encoding?(format : String, context = nil) : Bool
    "json" == format
  end

  def decode(data : _, format : String, context = nil) : SerializedAny
    SerializedAny.from_value JSON.parse(data).raw
  end

  def supports_decoding?(format : String, context = nil) : Bool
    "json" == format
  end
end

# Decode - Format => Array
# Encode - Array => Format

# Denormalize - Array => Obj
# Normalize - Obj => Array

# Deserialize - Format => Obj
# Serialize - Obj => Format

class Serializer
  include EncoderInterface
  include DecoderInterface

  @decoder : DecoderInterface
  @encoder : EncoderInterface

  def initialize(
    normalizers : Enumerable(NormalizerInterface) = [] of NormalizerInterface,
    encoders : Array(DecoderInterface | EncoderInterface)? = nil # = [] of DecoderInterface | EncoderInterface
  )
    real_decoders = [] of DecoderInterface
    real_encoders = [] of EncoderInterface

    encoders.try &.each do |encoder|
      if encoder.is_a?(DecoderInterface)
        real_decoders << encoder
      end

      if encoder.is_a?(EncoderInterface)
        real_encoders << encoder
      end
    end

    @decoder = ChainDecoder.new real_decoders
    @encoder = ChainEncoder.new real_encoders
  end

  def decode(data : _, format : String, context = nil) : SerializedAny
    @decoder.decode data, format, context
  end

  def encode(data : SerializedAny, format : String, context = nil) : String
    @encoder.encode data, format, context
  end

  def supports_decoding?(format : String, context = nil) : Bool
    @decoder.supports_decoding? format
  end

  def supports_encoding?(format : String, context = nil) : Bool
    @encoder.supports_encoding? format
  end
end

# pp SerializedAny.new({"foo" => "bar", 0 => 19})

data = %({"foo":"bar","age": 0,"owner": {"active":true}})
# # data = {"foo" => 10}

ser = Serializer.new encoders: [JSONEncoder.new]

pp ser.decode data, "json"
