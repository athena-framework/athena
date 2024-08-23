# Represents a controller action parameter. Stores metadata associated with it, such as its name, type, and default value if any.
struct Athena::Framework::Controller::ParameterMetadata(T)
  # Returns the name of the parameter.
  getter name : String

  # Returns `true` if this parameter has a default value set, otherwise `false`.
  getter? has_default : Bool

  # Returns annotation configurations registered via `ADI.configuration_annotation` and applied to this parameter.
  #
  # These configurations could then be accessed within `ATHR::Interface`s and/or `ATH::Listeners`s.
  getter annotation_configurations : ADI::AnnotationConfigurations

  # :nodoc:
  def initialize(
    @name : String,
    @has_default : Bool = false,
    @default_value : T? = nil,
    @annotation_configurations : ADI::AnnotationConfigurations = ADI::AnnotationConfigurations.new
  ); end

  # If `nil` is a valid value for the parameter.
  def nilable? : Bool
    {{T.nilable?}}
  end

  # Returns the default value for this parameter, raising an exception if it does not have one.
  def default_value : T
    raise ATH::Exception::Logic.new "Argument '#{@name}' does not have a default value." unless self.has_default?

    @default_value.not_nil!
  end

  # Returns the default value for this parameter, or `nil` if it does not have one.
  def default_value? : T?
    @default_value
  end

  # The type of the parameter, i.e. what its type restriction is.
  def type : T.class
    T
  end

  # Returns `true` if this parameter's `#type` includes the provided *klass*.
  #
  # ```
  # ATH::Controller::ParameterMetadata(Int32).new("foo").instance_of?(Int32)       # => true
  # ATH::Controller::ParameterMetadata(Int32 | Bool).new("foo").instance_of?(Bool) # => true
  # ATH::Controller::ParameterMetadata(Int32).new("foo").instance_of?(String)      # => false
  # ```
  def instance_of?(klass : Type.class) : Bool forall Type
    {{ T.union? ? T.union_types.any? { |t| t <= Type } : T <= Type }}
  end

  # Returns the metaclass of the first matching type variable that is an `#instance_of?` the provided *klass*, or `nil` if none match.
  # If this the `#type` is union, this would be the first viable type.
  #
  # ```
  # ATH::Controller::ParameterMetadata(Int32).new("foo").first_type_of(Int32)                            # => Int32.class
  # ATH::Controller::ParameterMetadata(String | Int32 | Bool).new("foo").first_type_of(Int32)            # => Int32.class
  # ATH::Controller::ParameterMetadata(String | Int8 | Float64 | Int64).new("foo").first_type_of(Number) # => Float64.class
  # ATH::Controller::ParameterMetadata(String | Int32 | Bool).new("foo").first_type_of(Float64)          # => nil
  # ```
  def first_type_of(klass : Type.class) forall Type
    {% if T.union? %}
      {% for t in T.union_types %}
        {% if t <= Type %}
          return {{t}}
        {% end %}
      {% end %}
    {% elsif T <= Type %}
      {{T}}
    {% end %}
  end
end
