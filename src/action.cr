# Parent type of a route just used for typing.
#
# See `ART::Action`.
abstract struct Athena::Routing::ActionBase; end

# Represents an endpoint within the application.

# Includes metadata about the endpoint, such as its controller, arguments, return type, and the action that should be executed.
struct Athena::Routing::Action(Controller, ActionType, ReturnType, ArgTypeTuple, ArgumentsType, ParamConverterType) < Athena::Routing::ActionBase
  # Returns the HTTP method associated with `self`.
  getter method : String

  # Returns the name of the the controller action related to `self`.
  getter name : String

  # Returns the URL path related to `self`.
  getter path : String

  # Returns any routing constraints related to `self`.
  getter constraints : Hash(String, Regex)

  # Returns an `Array(ART::Arguments::ArgumentMetadata)` that `self` requires.
  getter arguments : ArgumentsType

  # Returns an `Array(ART::ParamConverterInterface::ConfigurationInterface)` representing the `ARTA::ParamConverter`s applied to `self`.
  getter param_converters : ParamConverterType

  # Returns annotation configurations registered via `Athena::Config.configuration_annotation` and applied to `self`.
  #
  # These configurations could then be accessed within `ART::ParamConverterInterface`s and/or `ART::Listeners`s.
  # See `ART::Events::RequestAware` for an example.
  getter annotation_configurations : ACF::AnnotationConfigurations

  getter params : Array(ART::Params::ParamInterface)

  def initialize(
    @action : ActionType,
    @name : String,
    @method : String,
    @path : String,
    @constraints : Hash(String, Regex),
    @arguments : ArgumentsType,
    @param_converters : ParamConverterType,
    @annotation_configurations : ACF::AnnotationConfigurations,
    @params : Array(ART::Params::ParamInterface),
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

  # The `ART::Controller` that includes `self`.
  def controller : Controller.class
    Controller
  end

  # Executes the action related to `self` with the provided *arguments* array.
  def execute(arguments : Array) : ReturnType
    @action.call.call *{{ArgTypeTuple.type_vars.empty? ? "Tuple.new".id : ArgTypeTuple}}.from arguments
  end

  protected def apply_param_converters(converters : Hash(ART::ParamConverterInterface.class, ART::ParamConverterInterface), request : ART::Request) : Nil
    {% begin %}
      {% for idx in (0...ParamConverterType.size) %}
        %configuration = @param_converters[{{idx}}]
        converters[%configuration.converter].apply request, %configuration
      {% end %}
    {% end %}
  end

  # :nodoc:
  #
  # Creates an `ART::View` populated with the provided *data*.
  # Uses the action's return type to type the view.
  protected def create_view(data : ReturnType) : ART::View
    ART::View(ReturnType).new data
  end

  protected def create_view(data : _) : NoReturn
    raise "BUG:  Invoked wrong create_view overload."
  end

  # :nodoc:
  protected def copy_with(name _name = @name, method _method = @method)
    self.class.new(
      action: @action,
      name: _name,
      method: _method,
      path: @path,
      constraints: @constraints,
      arguments: @arguments,
      param_converters: @param_converters,
      annotation_configurations: @annotation_configurations,
      params: @params,
      _controller: Controller,
      _return_type: ReturnType,
      _arg_types: ArgTypeTuple,
    )
  end
end
