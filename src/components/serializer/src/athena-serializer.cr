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

  module Annotations
    annotation MaxDepth; end
    annotation SerializedName; end
    annotation SerializedPath; end
    annotation Ignore; end
    annotation Context; end
  end

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

  module Mapping
    module ClassMetadataInterface
      abstract def name
      abstract def add_property_metadata(metadata : ASR::Mapping::PropertyMetadataInterface) : Nil
      abstract def property_metadata : Hash(String, ASR::Mapping::PropertyMetadataInterface)

      # abstract def class_disriminator_mapping : ASR::Mapping::ClassDiscriminator?
      # abstract def class_disriminator_mapping=(mapping : ASR::Mapping::ClassDiscriminator?) : Nil
    end

    struct ClassMetadata(T)
      include ASR::Mapping::ClassMetadataInterface

      # :inherit:
      def name : T
        {{T.instance}}
      end

      # :inherit:
      getter property_metadata : Hash(String, ASR::Mapping::PropertyMetadataInterface) = {} of String => ASR::Mapping::PropertyMetadataInterface

      # :inherit:
      def add_property_metadata(metadata : ASR::Mapping::PropertyMetadataInterface) : Nil
        @property_metadata[metadata.name] = metadata
      end

      def short_name : String
        {{T.instance.name(generic_args: false).split("::").last}}
      end
    end

    module PropertyPathInterface
    end

    struct PropertyPath
      include PropertyPathInterface
    end

    module PropertyMetadataInterface
      abstract def name : String

      abstract def add_group(group : String) : Nil
      abstract def groups : Array(String)

      abstract def max_depth=(max_depth : Int32?)
      abstract def max_depth : Int32?

      abstract def serialized_name : String?
      abstract def serialized_name=(serialized_name : String?)

      abstract def serialized_path : ASR::Mapping::PropertyPath?
      abstract def serialized_path=(serialized_path : ASR::Mapping::PropertyPath?)

      abstract def ignored=(ignored : Bool)
      abstract def ignored? : Bool

      abstract def normalization_contexts : Hash(String, ASR::AbstractContext)
      abstract def normalization_contexts_for_group(groups : String | Enumerable(String)) : Array(ASR::AbstractContext)
      abstract def set_normalization_contexts_for_group(context : ASR::AbstractContext, groups : String | Enumerable(String)) : Nil

      abstract def denormalization_contexts : Hash(String, ASR::AbstractContext)
      abstract def denormalization_contexts_for_group(groups : String | Enumerable(String)) : Array(ASR::AbstractContext)
      abstract def set_denormalization_contexts_for_group(context : ASR::AbstractContext, groups : String | Enumerable(String)) : Nil
    end

    struct PropertyMetadata(IvarType, IvarIndex)
      include ASR::Mapping::PropertyMetadataInterface

      getter name : String
      getter groups : Array(String) = [] of String
      property max_depth : Int32?
      property serialized_name : String?
      property serialized_path : ASR::Mapping::PropertyPath?
      property? ignored : Bool
      getter normalization_contexts : Hash(String, ASR::AbstractContext) = {} of String => ASR::AbstractContext
      getter denormalization_contexts : Hash(String, ASR::AbstractContext) = {} of String => ASR::AbstractContext

      def initialize(
        @name : String,
        @max_depth : Int32? = nil,
        @serialized_name : String? = nil,
        @serialized_path : ASR::Mapping::PropertyPath? = nil,
        @ignored : Bool = false
      ); end

      def type : IvarType.class
        IvarType
      end

      def add_group(group : String) : Nil
        @groups << group unless @groups.includes? group
      end

      def normalization_contexts_for_group(groups : String | Enumerable(String)) : Array(ASR::AbstractContext)
      end

      def set_normalization_contexts_for_group(context : ASR::AbstractContext, groups : String | Enumerable(String)) : Nil
      end

      def denormalization_contexts_for_group(groups : String | Enumerable(String)) : Array(ASR::AbstractContext)
      end

      def set_denormalization_contexts_for_group(context : ASR::AbstractContext, groups : String | Enumerable(String)) : Nil
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
        str = data.raw.as String

        if (context = context[self]?) && (format = context.format)
          ::Time.parse str, format, ::Time::Location::UTC
        else
          ::Time.parse_rfc3339 data.raw.as(String)
        end
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

      record Context < ASR::AbstractContext, groups : Array(String)?, ignored_properties : Array(String) = [] of String # , properties : Hash(String)

      @default_context : Context

      def initialize(
        # @name_converter : ASR::NameConverter::Interface? = nil,
        *,
        groups : Array(String)? = nil,
        ignored_properties : Array(String) = [] of String,
        # properties : Array(String)? = nil,
      )
        @default_context = Context.new groups: groups, ignored_properties: ignored_properties # , properties: properties
      end

      def denormalize(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : T forall T
        # Cache key?
        # Validate Callbacks
        # Something about `value_type` context?

        allowed_properties = self.allowed_properties(T, context).map &.name
        normalized_data = self.prepare_for_denormalization data

        mapped_class = self.mapped_class data, T, context

        nested_properties = self.nested_properties mapped_class

        # TODO: Handle nested properties

        object = self.instantiate_object data, mapped_class, context, allowed_properties, format
        resolved_class = object.class

        normalized_data.raw.as(Hash).each do |key, value|
          name = if (v = key.raw).is_a? String
                   v
                 else
                   raise "BUG: Non-String key"
                 end

          # TODO: Handle name converter
          # Denormalization context

          if !allowed_properties.includes?(name) || !self.is_allowed_attribute(resolved_class, name, context[self]?)
            next
          end

          # Deep object to populate?

          self.set_value object, name, value
        end

        # TODO: This or just define a constructor via `ASR::Serializable`?
        GC.add_finalizer(object) if object.responds_to?(:finalize)

        object
      end

      def supports_denormalization?(data : ASR::Any, type : T.class, format : String? = nil, context : ASR::Context = ASR::Context.new) : Bool forall T
        {{ T <= ASR::Serializable }}
      end

      private def set_value(object : T, name : String, data : ASR::Any) : Nil forall T
        {% begin %}
          case name
          {% for ivar in T.instance_vars %}
            when {{ivar.name.stringify}} then pointerof(object.@{{ivar.name.id}}).value = self.convert({{ivar.type.id}}, data)
          {% end %}
          end
        {% end %}
      end

      # TODO: Better way to handle this?

      private def convert(type : Number.class, data : ASR::Any) : Number
        type.new! data.raw.as Number
      end

      private def convert(type : String.class, data : ASR::Any) : String
        data.raw.as String
      end

      private def convert(type : Bool.class, data : ASR::Any) : Bool
        data.raw.as Bool
      end

      private def convert(type : Array(T).class, data : ASR::Any) : Array(T) forall T
        data.raw.as(Array).map { |v| self.convert(T, v) }
      end

      # Overridable

      private def instantiate_object(data : ASR::Any, type : T.class, context : ASR::Context, allowed_properties : Array(String), format : String? = nil) : T forall T
        # TODO: Handle object to populate?
        # TODO: Is there a better/safer way to handle this?

        type.allocate
      end

      private def prepare_for_denormalization(data : ASR::Any) : ASR::Any
        data
      end

      # Internal

      private def allowed_properties(type : T, context : ASR::Context) : Array(ASR::Mapping::PropertyMetadataInterface) forall T
        # TODO: Do we actually need dedicated types for loading class metadata?
        class_metadata = ASR::Mapping::ClassMetadata(T).new

        # Check T for DiscriminatorMap, Groups, and Context annotations
        {% begin %}
          {% for ivar, idx in T.instance.instance_vars %}

            class_metadata.add_property_metadata ASR::Mapping::PropertyMetadata({{ivar.type.id}}, {{idx.id}}).new(
              {{ivar.name.stringify}},
              {{(ann = ivar.annotation(ASRA::MaxDepth)) ? ann[0] : nil}},
              {{(ann = ivar.annotation(ASRA::SerializedName)) ? ann[0] : nil}},
              nil,
              {{(ann = ivar.annotation(ASRA::Ignore)) ? true : false}},
            )

            # Apply class context
            # Apply class groups
          {% end %}

          # TODO: Merge in metadata from interfaces?
        {% end %}

        groups = self.groups context[self]?
        groups_have_been_defined = !groups.empty?
        groups = groups.push "Default", class_metadata.short_name

        class_metadata.property_metadata.each_value.select do |property_metadata|
          next false if property_metadata.ignored?
          next false if groups_have_been_defined && !((property_metadata.groups + ["*"]) & groups).empty?
          next false unless self.is_allowed_attribute T, property_metadata.name, context: context[self]?

          true
        end.to_a
      end

      private def is_allowed_attribute(type : T.class, name : String, context : Context?) : Bool forall T
        return false if (context.try(&.ignored_properties) || @default_context.ignored_properties).includes? name

        # TODO: Allow specifying what properties to return.

        true
      end

      private def groups(context : Context?) : Array(String)
        context.try(&.groups) || @default_context.groups || [] of String
      end

      private def nested_properties(type : T.class) : Hash(String, ASR::Mapping::PropertyPath) forall T
        # TODO: Support this

        {} of String => ASR::Mapping::PropertyPath
      end

      private def mapped_class(data : ASR::Any, type : T.class, context : ASR::Context) forall T
        # TODO: Handle object to populate?

        T
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

    @normalizers : Array(ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface)
    @decoder : ASR::Encoder::DecoderInterface
    @encoder : ASR::Encoder::EncoderInterface

    def initialize(
      normalizers : Array(ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface) = [] of ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface,
      encoders : Array(ASR::Encoder::DecoderInterface | ASR::Encoder::EncoderInterface)? = nil
    )
      @normalizers = normalizers.map &.as ASR::Normalizer::DenormalizerInterface | ASR::Normalizer::NormalizerInterface

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

    def []?(type : _)
      self.[]?(type.class)
    end

    def []?(type : T.class) forall T
      {% if T.has_constant? "Context" %}
        if typ = @context_map[type.to_s]?
          return typ.as T::Context
        end
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

class Models::User
  include ASR::Serializable

  getter name : String
  getter age : Int32
  getter active : Bool = true
  getter values : Array(Int32) = [] of Int32

  def initialize(@name, @age); end
end

record Book, title : String

serializer = ASR::Serializer.new(
  encoders: [ASR::Encoder::JSONEncoder.new],
  normalizers: [ASR::Normalizer::Object.new]
)

context = ASR::Context.new
  .for(ASR::Normalizer::Time, format: "%F")

# raw = %("2024-08-24")
# pp serializer.deserialize raw, Time, "json", context

# raw = %("9675aab2-63a3-4828-b661-b28ed9deb8a7")
# pp serializer.deserialize raw, UUID, "json", context

raw = %({"name":"Jon","age":16,"values":[6, 9, 12]})
pp serializer.deserialize raw, Models::User, "json"

# raw = %({"title":"Moby"})
# pp serializer.deserialize raw, Book, "json"
