# Parent type of a controller action just used for typing.
#
# See `AHK::Action`.
abstract class Athena::HTTPKernel::ActionBase
  abstract def resolve_arguments(value_resolvers : Array, request : AHTTP::Request) : Array

  abstract def execute(arguments : Array)

  # :inherit:
  def inspect(io : IO) : Nil
    io << "#<AHK::Action>"
  end
end

# Represents a controller action that will handle a request.
#
# Includes metadata about the endpoint, such as its action parameters and return type, and the action that should be executed.
class Athena::HTTPKernel::Action(ReturnType, ParameterTypeTuple, ParametersType) < Athena::HTTPKernel::ActionBase
  # Returns a tuple of `AHK::Controller::ParameterMetadata` representing the parameters this action expects.
  getter parameters : ParametersType

  def initialize(
    @action : Proc(ParameterTypeTuple, ReturnType),
    @parameters : ParametersType,
    # Don't bother making this an ivar since we just need it to set the generic type
    _return_type : ReturnType.class,
  ); end

  # Returns the type that this action returns.
  def return_type : ReturnType.class
    ReturnType
  end

  # Executes this action with the provided *arguments* array.
  def execute(arguments : Array) : ReturnType
    @action.call {{ParameterTypeTuple.type_vars.empty? ? "Tuple.new".id : ParameterTypeTuple}}.from arguments
  end

  # Resolves the arguments for this action for the given *request*.
  #
  # This is defined in here as opposed to `AHK::Controller::ArgumentResolver` so that the free vars are resolved correctly.
  # See https://forum.crystal-lang.org/t/incorrect-overload-selected-with-freevar-and-generic-inheritance/3625.
  def resolve_arguments(value_resolvers : Array, request : AHTTP::Request) : Array
    {% begin %}
      {% if 0 == ParametersType.size %}
        Tuple.new.to_a
      {% else %}
        {
          {% for idx in (0...ParametersType.size) %}
            begin
              %parameter = @parameters[{{idx}}]

              # Variadic parameters are not supported.
              # `nil` represents both the value `nil` and that resolver was unable to resolve a value
              # Each resolver can return at most one value.
              # First resolver to resolve a non-nil value wins, otherwise `nil` itself is used as the value,
              # assuming the parameter accepts nil, otherwise an error is raised.

               value = value_resolvers.each do |resolver|
                resolved_value = resolver.resolve request, %parameter
                break resolved_value unless resolved_value.nil?
              end

              if value.nil? && !%parameter.nilable?
                raise RuntimeError.new "AHK::Action requires that you provide a value for the '#{%parameter.name}' parameter. Either the parameter is nilable and no nil value has been provided, or no default value has been provided."
              end

              value
            end,
          {% end %}
        }.to_a
      {% end %}
    {% end %}
  end
end
