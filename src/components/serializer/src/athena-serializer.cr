require "semantic_version"
require "uuid"

require "json"
require "yaml"

require "athena-dependency_injection"

require "./annotations"
require "./any"
require "./context"
require "./serializable"
require "./serializer_interface"
require "./serializer"
require "./property_metadata"
require "./deserialization_context"
require "./serialization_context"

require "./construction/*"
require "./exception/*"
require "./exclusion_strategies/*"
require "./navigators/*"
require "./visitors/*"

# Convenience alias to make referencing `Athena::Serializer` types easier.
alias ASR = Athena::Serializer

# Convenience alias to make referencing `Athena::Serializer::Annotations` types easier.
alias ASRA = Athena::Serializer::Annotations

# :nodoc:
module JSON; end

# :nodoc:
module YAML; end

# Provides enhanced (de)serialization features.
module Athena::Serializer
  VERSION = "0.4.1"

  # Returns an `ASR::SerializerInterface` instance for ad-hoc (de)serialization.
  #
  # The serializer is cached and only instantiated once.
  class_getter serializer : ASR::SerializerInterface { ASR::Serializer.new }

  # The built-in supported formats.
  enum Format
    JSON
    YAML

    # Returns the `ASR::Visitors::SerializationVisitorInterface` related to `self`.
    def serialization_visitor
      case self
      in .json? then ASR::Visitors::JSONSerializationVisitor
      in .yaml? then ASR::Visitors::YAMLSerializationVisitor
      end
    end

    # Returns the `ASR::Visitors::DeserializationVisitorInterface` related to `self`.
    def deserialization_visitor
      case self
      in .json? then ASR::Visitors::JSONDeserializationVisitor
      in .yaml? then ASR::Visitors::YAMLDeserializationVisitor
      end
    end
  end

  # Contains all custom exceptions defined within `Athena::Serializer`.
  # Also acts as a marker that can be used to rescue all serializer related exceptions.
  module Exception; end

  # Exclusion Strategies allow controlling which properties should be (de)serialized.
  #
  # `Athena::Serializer` includes two common strategies: `ASR::ExclusionStrategies::Groups`, and `ASR::ExclusionStrategies::Version`.
  #
  # Custom strategies can be implemented by via `ExclusionStrategies::ExclusionStrategyInterface`.
  #
  # !!!todo
  #     Once feasible, support compile time exclusion strategies.
  module ExclusionStrategies; end

  # Used to denote a type that is (de)serializable.
  #
  # This module can be used to make the compiler happy in some situations, it doesn't do anything on its own.
  # You most likely want to use `ASR::Serializable` instead.
  #
  # ```
  # require "athena-serializer"
  #
  # abstract struct BaseModel
  #   # `ASR::Model` is needed here to ensure typings are correct for the deserialization process.
  #   # Child types should still include `ASR::Serializable`.
  #   include ASR::Model
  # end
  #
  # record ModelOne < BaseModel, id : Int32, name : String do
  #   include ASR::Serializable
  # end
  #
  # record ModelTwo < BaseModel, id : Int32, name : String do
  #   include ASR::Serializable
  # end
  #
  # record Unionable, type : BaseModel.class
  # ```
  module Model; end
end
