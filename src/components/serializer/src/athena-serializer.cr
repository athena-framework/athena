require "uuid"

require "json"
require "yaml"

# Convenience alias to make referencing `Athena::Serializer` types easier.
alias ASR = Athena::Serializer

# Convenience alias to make referencing `Athena::Serializer::Annotations` types easier.
alias ASRA = Athena::Serializer::Annotations

# Provides enhanced (de)serialization features.
module Athena::Serializer
  VERSION = "0.3.6"

  # Contains all custom exceptions defined within `Athena::Serializer`.
  # Also acts as a marker that can be used to rescue all serializer related exceptions.
  module Exception; end

  module Serializable; end

  module Annotations; end

  abstract struct AbstractContext; end

  struct Any
    alias Type = Nil | Bool | Int64 | Float64 | String | Array(ASR::Any) | Hash(ASR::Any, ASR::Any)

    # :nodoc:
    def self.new(raw : JSON::Any | YAML::Any) : self
      self.from_value raw.raw
    end

    def self.from_value(value : _) : self
      new(
        case value
        when Hash
          value.each_with_object({} of self => self) do |(k, v), hash|
            key = k.is_a?(self) ? k : new(k)
            value = v.is_a?(self) ? v : new(v)

            hash[key] = value
          end
        when Enumerable
          value.map do |v|
            v.is_a?(self) ? v : new(v)
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
    def [](key_or_index : _) : self
      case object = @raw
      when Hash
        object[self.class.new key_or_index]
      else
        raise "Expected Array or Hash for #[], not #{object.class}"
      end
    end

    # Assumes the underlying value is an `Array` and returns the element
    # at the given index, or `nil` if out of bounds.
    # Raises if the underlying value is not an `Array`.
    def []?(key_or_index : _) : self?
      case object = @raw
      when Hash
        object[self.class.new key_or_index]?
      else
        raise "Expected Array or Hash for #[]?, not #{object.class}"
      end
    end
  end

  module SerializerInterface
    abstract def serialize(data : _, format : String, context : ASR::Context = ASR::Context.new) : String
    abstract def deserialize(data : _, type : T.class, format : String, context : ASR::Context = ASR::Context.new) forall T
  end

  module Normalizer
    module NormalizerInterface
      abstract def normalize(data : _, format : String? = nil, context : ASR::Context = ASR::Context.new) : ASR::Any
      abstract def supports_normalization?(data : _, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool
    end

    module DenormalizerInterface
      abstract def denormalize(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) forall T
      abstract def supports_denormalization?(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T

      def denormalize(data : ASR::Any, type : _, format : String? = nil, context : ASR::Context = ASR::Context.new) : NoReturn
        raise "BUG: Invoked wrong denormalize overload."
      end

      def supports_denormalization?(data : ASR::Any, type : _, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool
        false
      end
    end

    struct Time
      include DenormalizerInterface

      record Context < ASR::AbstractContext, format : String? = nil, timezone : ::Time::Location? = nil

      def denormalize(data : ASR::Any, type : ::Time.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : ::Time
        pp! typeof(context[self])

        ::Time.parse_rfc3339 data.raw.as(String)
      end

      def supports_denormalization?(data : ASR::Any, type : ::Time.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T
        true
      end
    end

    struct UUID
      include DenormalizerInterface

      def denormalize(data : ASR::Any, type : ::UUID.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : ::UUID
        pp! typeof(context[self])

        ::UUID.parse?(data.raw.as(String)) || raise "Oops"
      end

      def supports_denormalization?(data : ASR::Any, type : ::UUID.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T
        true
      end
    end

    struct Object
      include DenormalizerInterface

      def denormalize(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : T forall T
        # Cache key?
        # Validate Callbacks

        self.construct data, T
      end

      def supports_denormalization?(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T
        {{ T <= Serializable }}
      end

      private def construct(data : ASR::Any, type : T.class) : T forall T
        {% begin %}
      instance = T.allocate

      # TODO: Filtering properties and stuff
      {% for ivar in T.instance_vars %}
        if any = data[{{ivar.name.stringify}}]?
          value = any.raw

          {% if ivar.type <= Number %}
            value = {{ivar.type.id}}.new! value.as Number
          {% elsif ivar.type <= Serializable %}
            value =
          {% end %}

          if value.is_a? ::{{ivar.type.id}}
            pointerof(instance.@{{ivar.name.id}}).value = value
          end
        end
      {% end %}

      instance
    {% end %}
      end
    end
  end

  module Encoder
    module DecoderInterface
      abstract def decode(data : _, format : String, context : ASR::Context = ASR::Context.new) : ASR::Any
      abstract def supports_decoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
    end

    class ChainDecoder
      include DecoderInterface

      @decoders_by_format = Hash(String, Int32).new

      def initialize(@decoders : Array(DecoderInterface))
      end

      def decode(data : _, format : String, context : ASR::Context = ASR::Context.new) : ASR::Any
        self.decoder(format, context).decode data, format, context
      end

      def supports_decoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
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
      abstract def encode(data : ASR::Any, format : String, context : ASR::Context = ASR::Context.new) : String
      abstract def supports_encoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
    end

    class ChainEncoder
      include EncoderInterface

      @encoders_by_format = Hash(String, Int32).new

      def initialize(@encoders : Array(EncoderInterface))
      end

      def encode(data : _, format : String, context : ASR::Context = ASR::Context.new) : String
        self.encoder(format, context).encode data, format, context
      end

      def supports_encoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
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

      def decode(data : _, format : String, context : ASR::Context = ASR::Context.new)
        JSON.parse data
      end

      def supports_decoding?(format : String) : Bool
        "json" == format
      end

      def encode(data : ASR::Any, format : String, context : ASR::Context = ASR::Context.new) : String
        data.to_json
      end

      def supports_encoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
        "json" == format
      end

      def decode(data : _, format : String, context : ASR::Context = ASR::Context.new) : ASR::Any
        ASR::Any.from_value JSON.parse(data).raw
      end

      def supports_decoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
        "json" == format
      end
    end
  end

  class Serializer
    include ASR::SerializerInterface
    include ASR::Encoder::DecoderInterface
    include ASR::Encoder::EncoderInterface
    include ASR::Normalizer::DenormalizerInterface

    @decoder : ASR::Encoder::DecoderInterface
    @encoder : ASR::Encoder::EncoderInterface

    def initialize(
      @normalizers : Array(ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface) = [] of ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface,
      encoders : Array(ASR::Encoder::DecoderInterface | ASR::Encoder::EncoderInterface)? = nil
    )
      real_decoders = [] of ASR::Encoder::DecoderInterface
      real_encoders = [] of ASR::Encoder::EncoderInterface

      encoders.try &.each do |encoder|
        if encoder.is_a?(ASR::Encoder::DecoderInterface)
          real_decoders << encoder
        end

        if encoder.is_a?(ASR::Encoder::EncoderInterface)
          real_encoders << encoder
        end
      end

      @decoder = ASR::Encoder::ChainDecoder.new real_decoders
      @encoder = ASR::Encoder::ChainEncoder.new real_encoders
    end

    def serialize(data : _, format : String, context : ASR::Context = ASR::Context.new) : String
    end

    def deserialize(data : _, type : T.class, format : String, context : ASR::Context = ASR::Context.new) : T forall T
      unless self.supports_decoding? format, context
        raise "Deserialization for the format is not supported."
      end

      self.denormalize self.decode(data, format, context), T, format, context
    end

    def denormalize(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : T forall T
      normalizer = self.denormalizer data, type, format, context

      # No normalizer but the underlying value is already the desired type
      if !normalizer && (d = data.raw.as? T)
        return d
      end

      # No normalizers
      if @normalizers.empty?
        raise "No normalizers"
      end

      unless normalizer
        raise "Could not denoramlize object of type, no supporting normalizer found."
      end

      # Errors

      normalizer.denormalize data, T, format, context
    end

    def supports_denormalization?(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T
      true
    end

    def decode(data : _, format : String, context : ASR::Context = ASR::Context.new) : ASR::Any
      @decoder.decode data, format, context
    end

    def encode(data : ASR::Any, format : String, context : ASR::Context = ASR::Context.new) : String
      @encoder.encode data, format, context
    end

    def supports_decoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
      @decoder.supports_decoding? format
    end

    def supports_encoding?(format : String, context : ASR::Context = ASR::Context.new) : Bool
      @encoder.supports_encoding? format
    end

    private def denormalizer(data : ASR::Any, type : T.class, format : String, context : ASR::Context = ASR::Context.new) : ASR::Normalizer::DenormalizerInterface? forall T
      @normalizers.each.select(ASR::Normalizer::DenormalizerInterface).find do |normalizer|
        normalizer.supports_denormalization? data, T, format, context
      end
    end
  end

  class Context
    @context_map = Hash(String, AbstractContext).new

    def [](type : _)
      self.[](type.class)
    end

    def [](type : T.class) forall T
      {% if T.has_constant? "Context" %}
        @context_map[type.to_s].as T::Context
      {% else %}
      {% T.raise "Cannot request context for #{T} as it does not define any." %}
    {% end %}
    end

    def for(type : T.class, **kwargs) : self forall T
      {% if T.has_constant? "Context" %}
        @context_map[type.to_s] = T::Context.new **kwargs
      {% else %}
        {% T.raise "Cannot add context for #{T} as it does not define any." %}
      {% end %}
      self
    end
  end
end

# Decode - Format => Array
# Encode - Array => Format

# Denormalize - Array => Obj
# Normalize - Obj => Array

# Deserialize - Format => Obj
# Serialize - Obj => Format

class User
  include ASR::Serializable

  getter name : String
  getter age : Int32
  getter active : Bool = true

  def initialize(@name, @age); end
end

record Book, title : String

serializer = ASR::Serializer.new encoders: [ASR::Encoder::JSONEncoder.new], normalizers: [ASR::Normalizer::Time.new, ASR::Normalizer::UUID.new] of ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface

context = ASR::Context.new.for(ASR::Normalizer::Time, format: "%D")

pp context

raw = %("2024-08-24T19:14:25+00:00")
pp serializer.deserialize raw, Time, "json", context

# raw = %("9675aab2-63a3-4828-b661-b28ed9deb8a7")
# pp serializer.deserialize raw, UUID, "json", context

# raw = %({"name":"Jon","age":16})
# pp serializer.deserialize raw, User, "json"

# raw = %({"title":"Moby"})
# pp serializer.deserialize raw, Book, "json"
