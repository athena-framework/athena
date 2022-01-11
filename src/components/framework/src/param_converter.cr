# A param converter allows applying custom logic in order to convert a primitive request parameter into a more complex type.
#
# A few common examples could be converting a date-time string into a `Time` object,
# converting a user's id into an actual `User` object, or deserializing a request body into an instance of `T`.
#
# ### Examples
#
# Defining a custom param converter requires the usage of two (optionally three) things:
#
# 1. An implementation of `self` to define the conversion logic.
# 1. The `ATHA::ParamConverter` annotation applied to an action to specify what argument should be converted, and what converter should be used.
# 1. An optional `ATH::ParamConverter::ConfigurationInterface` instance to define extra configuration options that can be used within the `ATHA::ParamConverter` annotation.
#
# Param converters are registered as services, and as such, may use any other registered services as a dependency via DI.
#
# ```
# require "athena"
#
# # Create a param converter struct to contain our conversion logic.
# @[ADI::Register]
# class MultiplyConverter < ATH::ParamConverter
#   # :inherit:
#   def apply(request : ATH::Request, configuration : Configuration) : Nil
#     arg_name = configuration.name
#
#     # No need to continue if the request does not have a value for this argument.
#     # The converter could also be setup to only set a value if it hasn't been set already.
#     return unless request.attributes.has? arg_name
#
#     # Retrieve the argument from the request's attributes as an Int32.
#     # Converters should also handle any errors that may occur,
#     # such as type conversion, validation, or business logic errors.
#     value = request.attributes.get arg_name, Int32
#
#     # Override the argument's value within the request attributes, restricted to `Int32` values.
#     request.attributes.set arg_name, value * 2, Int32
#   end
# end
#
# class ParamConverterController < ATH::Controller
#   # Use the ATHA::ParamConverter annotation to specify we want to use a param converter for the `num` argument, and that we want to use the `MultiplyConverter` for the conversion.
#   @[ARTA::Get(path: "/multiply/{num}")]
#   @[ATHA::ParamConverter("num", converter: MultiplyConverter)]
#   def multiply(num : Int32) : Int32
#     num
#   end
# end
#
# ATH.run
#
# # GET /multiply/3 # => 6
# ```
#
# #### Additional Configuration
#
# By default, the *configuration* argument to `#apply` contains the name of the argument that should be converted, and a reference to the class of `self`.
# However, it can be augmented with additional data by using the `ATH::ParamConverter.configuration` macro.
#
# For example, lets enhance the previous example to allow specifying the multiplier, versus it being hard-coded as `2`.
#
# ```
# require "athena"
#
# @[ADI::Register]
# class MultiplyConverter < ATH::ParamConverter
#   # Use the `configuration` macro to define the configuration object that `self` should use.
#   # Adds an additional argument to allow specifying the multiplier.
#   #
#   # Configuration data can be made optional by setting default values.
#   configuration by : Int32
#
#   # :inherit:
#   def apply(request : ATH::Request, configuration : Configuration) : Nil
#     arg_name = configuration.name
#
#     return unless request.attributes.has? arg_name
#
#     value = request.attributes.get arg_name, Int32
#
#     # Use the multiplier from the configuration object.
#     request.attributes.set arg_name, value * configuration.by, Int32
#   end
# end
#
# class ParamConverterController < ATH::Controller
#   # Specify the multiplier to use for the conversion; in this case `4`.
#   @[ARTA::Get(path: "/multiply/{num}")]
#   @[ATHA::ParamConverter("num", converter: MultiplyConverter, by: 4)]
#   def multiply(num : Int32) : Int32
#     num
#   end
# end
#
# ATH.run
#
# # GET /multiply/3 # => 12
# ```
#
# #### Type Safety
#
# From the previous examples, if you were to use the `MultiplyConverter` on a controller argument that is _NOT_ an `Int32` type,
# you would get a `500` response at runtime due to the `String` argument not being able to be casted to an `Int32` when fetching the attribute's value.
# This is less than ideal as it could lead to a hard to catch bug. To better solve this, and give a better error message when incorrectly used, we can utilize free variables.
#
# Each `ATH::ParamConverter::ConfigurationInterface` exposes the related controller action's type via a generic.
# This feature can be used to create overloads of `ATH::ParamConverter#apply` to handle specific types, or a catch all that could raise a compile time error.
#
# For example, let's iterate on the `MultiplyConverter` to make it handle `Int32` arguments and raise a compile time error if used on something else:
#
# ```
# @[ADI::Register]
# class MultiplyConverter < ATH::ParamConverter
#   # `configuration` macro is same as previous example.
#
#   # :inherit:
#   def apply(request : ATH::Request, configuration : Configuration(Int32)) : Nil
#     # Method body is same as previous example.
#   end
#
#   # :inherit:
#   def apply(request : ATH::Request, configuration : Configuration(T)) : Nil forall T
#     {% T.raise "MultiplyConverter does not support arguments of type '#{T}'." %}
#   end
# end
# ```
#
# In this example we updated the second argument of the `#apply` method to take an `Int32` generic argument.
# This will restrict that method to only handle instances where the param converter was applied to an argument of type `Int32`.
# The second overload handles all other types as it is a free variable.
# This overload then raises a compile time error if this converter is ever applied to an argument that is _NOT_ an `Int32`.
# Ultimately, this makes the converter compile time safe.
#
# This approach could also be used to handle multiple types of arguments within dedicated methods where the type is more well known.
abstract class Athena::Framework::ParamConverter
  # The tag name to apply to `self` in order for it to be registered with `ATH::Listeners::ParamConverter`.
  TAG = "athena.param_converter"

  # Apply `TAG` to all `AED::EventListenerInterface` instances automatically.
  ADI.auto_configure Athena::Framework::ParamConverter, {tags: [ATH::ParamConverter::TAG]}

  # Allows defining extra configuration data that can be supplied within the `ATHA::ParamConverter` annotation.
  # By default this type includes the name of the argument that should be converted and the
  # the `ATH::ParamConverter` that should be used for the conversion.
  #
  # The `ArgType` generic represents the type of the controller action argument `self` relates to.
  #
  # See the [Additional Configuration][Athena::Framework::ParamConverter--additional-configuration] example of `ATH::ParamConverter` for more information.
  abstract struct ConfigurationInterface(ArgType)
    # Returns the type of the argument the converter is applied to.
    getter type : ArgType.class = ArgType

    # Returns the name of the argument the converter should be applied to.
    getter name : String

    # Returns the converter class that should be used to convert the argument.
    getter converter : ATH::ParamConverter.class

    def initialize(@name : String, @converter : ATH::ParamConverter.class); end
  end

  # :nodoc:
  #
  # This is defined here so that the manual abstract def checks can "see" the `Configuration` type.
  struct Configuration(ArgType) < ConfigurationInterface(ArgType); end

  # Only define the default configuration method if the converter does not define a customer one.
  # Because the inherited hook is invoked on the same line as the inheritance happens, e.g. `< ATH::ParamConverter`,
  # the `configuration` macro hasn't been expanded yet making it seem like it wasn't defined.
  #
  # Solve this by defining the logic in a `finished` hook to delay execution until all types have been parsed,
  # and only define the type if it does not already exist.
  macro inherited
    macro finished
      {% verbatim do %}
        {% unless @type.has_constant? "Configuration" %}
          # Configuration for `{{@type.name}}`.
          struct Configuration(ArgType) < ConfigurationInterface(ArgType); end
        {% end %}
      {% end %}
    end

    # :nodoc:
    def apply(request : ATH::Request, configuration : Configuration) : Nil
      \{% @type.raise "abstract `def Athena::Framework::ParamConverter#apply(request : ATH::Request, configuration : Configuration)` must be implemented by '#{@type}'." %}
    end
  end

  # :nodoc:
  def apply(request : ATH::Request, configuration) : NoReturn
    raise "BUG:  Invoked wrong `apply` overload."
  end

  # Helper macro for defining an `ATH::ParamConverter::ConfigurationInterface`; similar to the `record` macro.
  # Accepts a variable amount of variable names, types, and optionally default values.
  #
  # Optionally allows for one or more *type_vars* constants that will be added to the generated configuration type as generic variables.
  # This macro can be used with a block in order to define additional methods to the generated configuration type, same as the `record` macro.
  #
  # See the [Additional Configuration][Athena::Framework::ParamConverter--additional-configuration] example of `ATH::ParamConverter` for more information.
  macro configuration(*args, type_vars = nil)
    {% begin %}
      # Configuration for `{{@type.name}}`.
      {% if type_vars %}\
        struct Configuration(ArgType, {{type_vars.is_a?(Path) ? type_vars.id : type_vars.splat}}) < ConfigurationInterface(ArgType)
      {% else %}
        struct Configuration(ArgType) < ConfigurationInterface(ArgType)
      {% end %}
        {% for arg in args %}
          getter {{arg}}
        {% end %}

        def initialize(
          name : String,
          converter : ATH::ParamConverter.class,
          {% for arg in args %}
            @{{arg}},
          {% end %}
        )
          super name, converter
        end

        {{yield}}
      end
    {% end %}
  end
end
