# Parent type of a route just used for typing.
#
# See `ATH::Action`.
abstract struct Athena::Framework::ActionBase; end

# Represents a controller action that will handle a request.
#
# Includes metadata about the endpoint, such as its controller, arguments, return type, and the action that should be executed.
struct Athena::Framework::Action(Controller, ReturnType, ArgTypeTuple, ArgumentsType) < Athena::Framework::ActionBase
  # Returns an `Array(ATH::Arguments::ArgumentMetadata)` that `self` requires.
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

  # Creates an `ATH::View` populated with the provided *data*.
  # Uses the action's return type to type the view.
  protected def create_view(data : ReturnType) : ATH::View
    ATH::View(ReturnType).new data
  end

  protected def create_view(data : _) : NoReturn
    raise "BUG:  Invoked wrong `create_view` overload."
  end
end
