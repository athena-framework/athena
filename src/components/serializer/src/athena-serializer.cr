require "semantic_version"
require "uuid"

require "json"
require "yaml"

require "athena-config"

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
require "./exceptions/*"
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

# Athena's Serializer component, `ASR` for short, adds enhanced (de)serialization features to your project.
#
# ## Getting Started
#
# If using this component within the [Athena Framework][Athena::Framework], it is already installed and required for you.
# Checkout the [manual](/architecture/serializer) for some additional information on how to use it within the framework.
#
# If using it outside of the framework, you will first need to add it as a dependency:
#
# ```yaml
# dependencies:
#   athena-serializer:
#     github: athena-framework/serializer
#     version: ~> 0.3.0
# ```
#
# Then run `shards install`, being sure to require it via `require "athena-serializer"`.
#
# ## Usage
#
# See the `ASR::Annotations` namespace a complete list of annotations, as well as each annotation for more detailed information.
#
# ```
# # ExclusionPolicy specifies that all properties should not be (de)serialized
# # unless exposed via the `ASRA::Expose` annotation.
# @[ASRA::ExclusionPolicy(:all)]
# @[ASRA::AccessorOrder(:alphabetical)]
# class Example
#   include ASR::Serializable
#
#   # Groups can be used to create different "views" of a type.
#   @[ASRA::Expose]
#   @[ASRA::Groups("details")]
#   property name : String
#
#   # The `ASRA::Name` controls the name that this property
#   # should be deserialized from or be serialized to.
#   # It can also be used to set the default serialized naming strategy on the type.
#   @[ASRA::Expose]
#   @[ASRA::Name(deserialize: "a_prop", serialize: "a_prop")]
#   property some_prop : String
#
#   # Define a custom accessor used to get the value for serialization.
#   @[ASRA::Expose]
#   @[ASRA::Groups("default", "details")]
#   @[ASRA::Accessor(getter: get_title)]
#   property title : String
#
#   # ReadOnly properties cannot be set on deserialization
#   @[ASRA::Expose]
#   @[ASRA::ReadOnly]
#   property created_at : Time = Time.utc
#
#   # Allows the property to be set via deserialization,
#   # but not exposed when serialized.
#   @[ASRA::IgnoreOnSerialize]
#   property password : String?
#
#   # Because of the `:all` exclusion policy, and not having the `ASRA::Expose` annotation,
#   # these properties are not exposed.
#   getter first_name : String?
#   getter last_name : String?
#
#   # Runs directly after `self` is deserialized
#   @[ASRA::PostDeserialize]
#   def split_name : Nil
#     @first_name, @last_name = @name.split(' ')
#   end
#
#   # Allows using the return value of a method as a key/value in the serialized output.
#   @[ASRA::VirtualProperty]
#   def get_val : String
#     "VAL"
#   end
#
#   private def get_title : String
#     @title.downcase
#   end
# end
#
# obj = ASR.serializer.deserialize Example, %({"name":"FIRST LAST","a_prop":"STR","title":"TITLE","password":"monkey123","created_at":"2020-10-10T12:34:56Z"}), :json
# obj                                                                                     # => #<Example:0x7f3e3b106740 @created_at=2020-07-05 23:06:58.943298289 UTC, @name="FIRST LAST", @some_prop="STR", @title="TITLE", @password="monkey123", @first_name="FIRST", @last_name="LAST">
# ASR.serializer.serialize obj, :json                                                     # => {"a_prop":"STR","created_at":"2020-07-05T23:06:58.94Z","get_val":"VAL","name":"FIRST LAST","title":"title"}
# ASR.serializer.serialize obj, :json, ASR::SerializationContext.new.groups = ["details"] # => {"name":"FIRST LAST","title":"title"}
# ```
module Athena::Serializer
  VERSION = "0.3.2"

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

  # Exclusion Strategies allow controlling which properties should be (de)serialized.
  #
  # `Athena::Serializer` includes two common strategies: `ASR::ExclusionStrategies::Groups`, and `ASR::ExclusionStrategies::Version`.
  #
  # Custom strategies can be implemented by via `ExclusionStrategies::ExclusionStrategyInterface`.
  #
  # !!!todo
  #     Once feasible, support compile time exclusion strategies.
  module Athena::Serializer::ExclusionStrategies; end

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
  module Athena::Serializer::Model; end
end
