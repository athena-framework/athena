# Default implementation of `ASR::SerializerInterface`.
#
# Provides the main API used to (de)serialize objects.
#
# Custom formats can be implemented by creating the required visitors for that type, then overriding `#get_deserialization_visitor_class` and `#get_serialization_visitor_class`.
#
# ```
# # Redefine the visitor class getters in order to first check for custom formats.
# # This assumes these visitor types are defined, with the proper logic to handle
# # the (de)serialization process.
# struct Athena::Serializer::Serializer
#   protected def get_deserialization_visitor_class(format : ASR::Format | String)
#     return MessagePackDeserializationVisitor if format == "message_pack"
#
#     previous_def
#   end
#
#   protected def get_serialization_visitor_class(format : ASR::Format | String)
#     return MessagePackSerializationVisitor if format == "message_pack"
#
#     previous_def
#   end
# end
# ```
struct Athena::Serializer::Serializer
  include Athena::Serializer::SerializerInterface

  def initialize(@navigator_factory : ASR::Navigators::NavigatorFactoryInterface = ASR::Navigators::NavigatorFactory.new); end

  # :inherit:
  def deserialize(type : _, data : String | IO, format : ASR::Format | String, context : ASR::DeserializationContext = ASR::DeserializationContext.new)
    # Initialize the context.  Currently just used to apply default exclusion strategies
    context.init

    visitor = self.get_deserialization_visitor_class(format).new
    navigator = @navigator_factory.get_deserialization_navigator visitor, context

    visitor.navigator = navigator

    navigator.accept type, visitor.prepare data
  end

  # :inherit:
  def serialize(data : _, format : ASR::Format | String, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : String
    String.build do |str|
      serialize data, format, str, context, **named_args
    end
  end

  # :inherit:
  def serialize(data : _, format : ASR::Format | String, io : IO, context : ASR::SerializationContext = ASR::SerializationContext.new, **named_args) : Nil
    # Initialize the context.  Currently just used to apply default exclusion strategies
    context.init

    visitor = self.get_serialization_visitor_class(format).new(io, named_args)
    navigator = @navigator_factory.get_serialization_navigator visitor, context

    visitor.navigator = navigator

    visitor.prepare

    navigator.accept data

    visitor.finish
  end

  # Returns the `ASR::Visitors::DeserializationVisitorInterface.class` for the given *format*.
  #
  # Can be redefined in order to allow resolving custom formats.
  protected def get_deserialization_visitor_class(format : ASR::Format | String)
    return format.deserialization_visitor if format.is_a? ASR::Format

    ASR::Format.parse(format).deserialization_visitor
  end

  # Returns the `ASR::Visitors::SerializationVisitorInterface.class` for the given *format*.
  #
  # Can be redefined in order to allow resolving custom formats.
  protected def get_serialization_visitor_class(format : ASR::Format | String)
    return format.serialization_visitor if format.is_a? ASR::Format

    ASR::Format.parse(format).serialization_visitor
  end
end
