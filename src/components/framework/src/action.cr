# Parent type of a route just used for typing.
#
# See `ATH::Action`.
abstract struct Athena::Framework::ActionBase; end

# Represents a controller action that will handle a request.
#
# Includes metadata about the endpoint, such as its controller, arguments, return type, and the action that should be executed.
struct Athena::Framework::Action(Controller, ActionType, ReturnType, ArgTypeTuple, ArgumentsType, ParamConverterType) < Athena::Framework::ActionBase
  # Returns an `Array(ATH::Arguments::ArgumentMetadata)` that `self` requires.
  getter arguments : ArgumentsType

  # Returns a `Tuple` of `ATH::ParamConverter::ConfigurationInterface` representing the `ATHA::ParamConverter`s applied to `self`.
  getter param_converters : ParamConverterType

  # Returns annotation configurations registered via `Athena::Config.configuration_annotation` and applied to `self`.
  #
  # These configurations could then be accessed within `ATH::ParamConverter`s and/or `ATH::Listeners`s.
  # See `ATH::Events::RequestAware` for an example.
  getter annotation_configurations : ACF::AnnotationConfigurations

  getter params : Array(ATH::Params::ParamInterface)

  def initialize(
    @action : ActionType,
    @arguments : ArgumentsType,
    @param_converters : ParamConverterType,
    @annotation_configurations : ACF::AnnotationConfigurations,
    @params : Array(ATH::Params::ParamInterface),
    # Don't bother making these ivars since we just need them to set the generic types
    _controller : Controller.class,
    _return_type : ReturnType.class,
    _arg_types : ArgTypeTuple.class
  )
  end

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
    @action.call.call *{{ArgTypeTuple.type_vars.empty? ? "Tuple.new".id : ArgTypeTuple}}.from arguments
  end

  # Applies all of the `ATH::ParamConverter::ConfigurationInterface`s on `self` against the provided `request` and *converters*.
  #
  # This is defined in here as opposed to `ATH::Listeners::ParamConverter` so that the free vars are resolved correctly.
  # See https://forum.crystal-lang.org/t/incorrect-overload-selected-with-freevar-and-generic-inheritance/3625.
  protected def apply_param_converters(converters : Hash(ATH::ParamConverter.class, ATH::ParamConverter), request : ATH::Request) : Nil
    {% begin %}
      {% for idx in (0...ParamConverterType.size) %}
        %configuration = @param_converters[{{idx}}]
        converters[%configuration.converter].apply request, %configuration
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
