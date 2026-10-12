@[ADI::Register]
@[ADI::AsAlias(ATH::Serializer::Interface)]
# Implements `ATH::Serializer::Interface` with the [Serializer](/Serializer/) component.
#
# Types that include `JSON::Serializable`, but not `ASR::Serializable`, are (de)serialized via `JSON::Serializable` instead.
struct Athena::Framework::Serializer::ComponentSerializer
  include Athena::Framework::Serializer::Interface

  def initialize(@serializer : ASR::SerializerInterface); end

  # :inherit:
  def serialize(data : T, format : String, context : ATH::View::Context) : String forall T
    {% begin %}
      {%
        types_to_recurse = [T]

        types_to_recurse.each do |t|
          t = t.resolve

          if t.union?
            t.union_types.each do |ut|
              types_to_recurse << ut
            end
          elsif t <= NamedTuple
            t.keys.each do |k|
              types_to_recurse << t[k].resolve
            end
          elsif t <= Enumerable
            t.type_vars.each do |ut|
              types_to_recurse << ut
            end

            # Use `to_json` if a type includes `JSON::Serializable` but not `ASR::Serializable`
          elsif (t <= JSON::Serializable) && !(t <= ASR::Serializable)
            use_serializer_component = false

            # Use the serializer component if the type is `ASR::Serializable`
          elsif t <= ASR::Serializable
            use_serializer_component = true
          else
            # Fallback on the serializer component
            use_serializer_component = true
          end
        end
      %}

      {% if use_serializer_component == true %}
        self.serialize_with_component data, format, context
      {% else %}
        data.to_json
      {% end %}
    {% end %}
  end

  # :inherit:
  def deserialize(data : IO, type : ASR::Serializable.class, format : String)
    @serializer.deserialize type, data, format
  rescue ex : ASR::Exception::DeserializationException
    raise AHK::Exception::BadRequest.new "Malformed JSON payload.", cause: ex
  end

  # :ditto:
  def deserialize(data : IO, type : JSON::Serializable.class, format : String)
    type.from_json data
  end

  # :ditto:
  def deserialize(data : IO, type : _, format : String) : Nil
  end

  private def serialize_with_component(data : _, format : String, context : ATH::View::Context) : String
    serialization_context = ASR::SerializationContext.new

    context.emit_nil?.try do |emit_nil|
      serialization_context.emit_nil = emit_nil
    end

    context.version.try do |version|
      serialization_context.version = version
    end

    context.groups.try do |groups|
      serialization_context.groups = groups
    end

    serialized_data = @serializer.serialize data, format, serialization_context

    # If the serialized data is "null", but the data is not `nil`, assume this means the serializer component failed to serialize it,
    # raise an error as it is likely the user forgot to include either `JSON::Serializable` or `ASR::Serializable`.
    if "null" == serialized_data && !data.nil?
      raise AHK::Exception::Logic.new "Failed to serialize response body. Did you forget to include either `JSON::Serializable` or `ASR::Serializable`?"
    end

    serialized_data
  end
end
