# Parent type of a controller action just used for typing.
#
# See `ATH::Action`.
abstract struct Athena::Framework::ActionBase; end

# Represents a controller action that will handle a request.
#
# Includes metadata about the endpoint, such as its controller, action parameters and return type, and the action that should be executed.
struct Athena::Framework::Action(Controller, ReturnType, ParameterTypeTuple, ParametersType) < Athena::Framework::ActionBase
  # Returns a tuple of `ATH::Controller::ParameterMetadata` representing the parameters this action expects.
  getter parameters : ParametersType

  # Returns annotation configurations registered via `Athena::Config.configuration_annotation` and applied to this action.
  #
  # These configurations could then be accessed within `ATHR::Interface`s and/or `ATH::Listeners`s.
  getter annotation_configurations : ADI::AnnotationConfigurations

  def initialize(
    @action : Proc(ParameterTypeTuple, ReturnType),
    @parameters : ParametersType,
    @annotation_configurations : ADI::AnnotationConfigurations,
    # Don't bother making these ivars since we just need them to set the generic types
    _controller : Controller.class,
    _return_type : ReturnType.class,
  ); end

  # Returns the type that this action returns.
  def return_type : ReturnType.class
    ReturnType
  end

  # Returns the `ATH::Controller` that this action is a part of.
  def controller : Controller.class
    Controller
  end

  # Executes this action with the provided *arguments* array.
  def execute(arguments : Array) : ReturnType
    @action.call {{ParameterTypeTuple.type_vars.empty? ? "Tuple.new".id : ParameterTypeTuple}}.from arguments
  end

  # Resolves the arguments for this action for the given *request*.
  #
  # This is defined in here as opposed to `ATH::Controller::ArgumentResolver` so that the free vars are resolved correctly.
  # See https://forum.crystal-lang.org/t/incorrect-overload-selected-with-freevar-and-generic-inheritance/3625.
  protected def resolve_arguments(value_resolvers : Array(ATHR::Interface), request : ATH::Request) : Array
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
              # TODO: Determine if that is robust enough, or we need some other implementation.

               value = value_resolvers.each do |resolver|
                resolved_value = resolver.resolve request, %parameter
                break resolved_value unless resolved_value.nil?
              end

              if value.nil? && !%parameter.nilable?
                raise RuntimeError.new "Controller '#{request.attributes.get "_controller"}' requires that you provide a value for the '#{%parameter.name}' parameter. Either the parameter is nilable and no nil value has been provided, or no default value has been provided."
              end

              value
            end,
          {% end %}
        }.to_a
      {% end %}
    {% end %}
  end

  # Creates an `ATH::View` populated with the provided *data*.
  # Uses the action's return type to type the view.
  protected def create_view(data : ReturnType) : ATH::View
    ATH::View(ReturnType).new data
  end

  protected def create_view(data : _) : NoReturn
    raise "BUG:  Invoked wrong `create_view` overload."
  end
end
