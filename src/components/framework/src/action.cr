# Parent type of a controller action just used for typing.
#
# See `ATH::Action`.
abstract struct Athena::Framework::ActionBase; end

# Represents a controller action that will handle a request.
#
# Includes metadata about the endpoint, such as its controller, arguments, return type, and the action that should be executed.
struct Athena::Framework::Action(Controller, ReturnType, ArgTypeTuple, ArgumentsType) < Athena::Framework::ActionBase
  # Returns a tuple of `ATH::Arguments::ArgumentMetadata` representing the arguments this route expects.
  getter arguments : ArgumentsType

  # Returns annotation configurations registered via `Athena::Config.configuration_annotation` and applied to `self`.
  #
  # These configurations could then be accessed within `ATH::ParamConverter`s and/or `ATH::Listeners`s.
  # See `ATH::Events::RequestAware` for an example.
  getter annotation_configurations : ACF::AnnotationConfigurations

  getter params : Array(ATH::Params::ParamInterface)

  def initialize(
    @action : Proc(ArgTypeTuple, ReturnType),
    @arguments : ArgumentsType,
    @annotation_configurations : ACF::AnnotationConfigurations,
    @params : Array(ATH::Params::ParamInterface),
    # Don't bother making these ivars since we just need them to set the generic types
    _controller : Controller.class,
    _return_type : ReturnType.class
  ); end

  # The type that `self`'s route should return.
  def return_type : ReturnType.class
    ReturnType
  end

  # The `ATH::Controller` that includes `self`.
  def controller : Controller.class
    Controller
  end

  # Executes the action related to `self` with the provided *arguments* array.
  def execute(arguments : Array) : ReturnType
    @action.call {{ArgTypeTuple.type_vars.empty? ? "Tuple.new".id : ArgTypeTuple}}.from arguments
  end

  # Resolves the arguments for this action for the given *request*.
  #
  # This is defined in here as opposed to `ATH::Arguments::ArgumentResolver` so that the free vars are resolved correctly.
  # See https://forum.crystal-lang.org/t/incorrect-overload-selected-with-freevar-and-generic-inheritance/3625.
  protected def resolve_arguments(resolvers : Array(ATHR::Interface), request : ATH::Request) : Array
    {% begin %}
      {% if 0 == ArgumentsType.size %}
        Tuple.new.to_a
      {% else %}
        {
          {% for idx in (0...ArgumentsType.size) %}
            begin
              %argument = @arguments[{{idx}}]

              # Variadic parameters are not supported.
              # `nil` represents both the value `nil` and that resolver was unable to resolve a value
              # Each resolver can return at most one value.
              # First resolver to resolve a non-nil value wins, otherwise `nil` itself is used as the value,
              # assuming the argument accepts nil, otherwise an error is raised.
              # TODO: Determine if that is robust enough, or we need some other implementation.

               value = resolvers.each do |resolver|
                resolved_value = resolver.resolve request, %argument
                break resolved_value unless resolved_value.nil?
              end

              if value.nil? && !%argument.nilable?
                raise RuntimeError.new "Controller '#{request.attributes.get "_controller"}' requires that you provide a value for the '#{%argument.name}' parameter. Either the argument is nilable and no nil value has been provided, or no default value has been provided."
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
