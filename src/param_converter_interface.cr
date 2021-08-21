# A param converter allows applying custom logic in order to convert a primitive request parameter into a more complex type.
#
# A few common examples could be converting a date-time string into a `Time` object,
# converting a user's id into an actual `User` object, or deserializing a request body into an instance of T.
#
# ### Examples
#
# Defining a custom param converter requires the usage of two (optionally three) things:
#
# 1. An implementation of `self` to define the conversion logic.
# 1. The `ARTA::ParamConverter` annotation applied to an action to specify what argument should be converted, and what converter should be used.
# 1. An optional `ART::ParamConverterInterface::ConfigurationInterface` instance to define extra configuration options that can be used within the `ARTA::ParamConverter` annotation.
#
# Param converters are registered as services, and as such, may use any other registered services as a dependency via DI.
#
# ```
# require "athena"
#
# # Create a param converter struct to contain our conversion logic.
# @[ADI::Register]
# struct MultiplyConverter < ART::ParamConverterInterface
#   # :inherit:
#   def apply(request : ART::Request, configuration : Configuration) : Nil
#     arg_name = configuration.name
#
#     # No need to continue if the request does not have a value for this argument.
#     # The converter could also be setup to only set a value if it hasn't been set already.
#     return unless request.attributes.has? arg_name
#
#     # Retieve the argument from the request's attributes as an Int32.
#     # Converters should also handle any errors that may occur,
#     # such as type conversion, validation, or business logic errors.
#     value = request.attributes.get arg_name, Int32
#
#     # Override the argument's value within the request attributes, restricted to `Int32` values.
#     request.attributes.set arg_name, value * 2, Int32
#   end
# end
#
# class ParamConverterController < ART::Controller
#   # Use the ARTA::ParamConverter annotation to specify we want to use a param converter for the `num` argument, and that we want to use the `MultiplyConverter` for the conversion.
#   @[ARTA::Get(path: "/multiply/:num")]
#   @[ARTA::ParamConverter("num", converter: MultiplyConverter)]
#   def multiply(num : Int32) : Int32
#     num
#   end
# end
#
# ART.run
#
# # GET /multiply/3 # => 6
# ```
#
# #### Additional Configuration
# By default, the *configuration* argument to `#apply` contains the name of the argument that should be converted, and a reference to the class of `self`.
# However, it can be augmented with additional data by using the `ART::ParamConverterInterface.configuration` macro.
#
# For example, lets enhance the previous example to allow specifying the multiplier, versus it being hard-coded as `2`.
#
# ```
# require "athena"
#
# @[ADI::Register]
# struct MultiplyConverter < ART::ParamConverterInterface
#   # Use the `configuration` macro to define the configuration object that `self` should use.
#   # Adds an additional argument to allow specifying the multiplier.
#   #
#   # Configuration data can be made optional by setting default values.
#   configuration by : Int32
#
#   # :inherit:
#   def apply(request : ART::Request, configuration : Configuration) : Nil
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
# class ParamConverterController < ART::Controller
#   # Specify the multiplier to use for the conversion; in this case `4`.
#   @[ARTA::Get(path: "/multiply/:num")]
#   @[ARTA::ParamConverter("num", converter: MultiplyConverter, by: 4)]
#   def multiply(num : Int32) : Int32
#     num
#   end
# end
#
# ART.run
#
# # GET /multiply/3 # => 12
# ```
abstract struct Athena::Routing::ParamConverterInterface
  # The tag name to apply to `self` in order for it to be registered with `ART::Listeners::ParamConverter`.
  TAG = "athena.param_converter"

  # Apply `TAG` to all `AED::EventListenerInterface` instances automatically.
  ADI.auto_configure Athena::Routing::ParamConverterInterface, {tags: [ART::ParamConverterInterface::TAG]}

  # Allows defining extra configuration data that can be supplied within the `ARTA::ParamConverter` annotation.
  # By default this type includes the name of the argument that should be converted and the
  # the `ART::ParamConverterInterface` that should be used for the conversion.
  #
  # See the "Additional Configuration" example of `ParamConverterInterface` for more information.
  abstract struct ConfigurationInterface
    # The name of the argument the converter should be applied to.
    getter name : String

    # The converter class that should be used to convert the argument.
    getter converter : ART::ParamConverterInterface.class

    def initialize(@name : String, @converter : ART::ParamConverterInterface.class); end
  end

  # Represents an `ART::ParamConverterInterface::ConfigurationInterface` who is
  # aware of the related `ART::ParamConverterInterface` argument's type.
  #
  # Allows support for generic converters that derive the type to do something from the type of the related argument.
  abstract struct ArgAwareConfiguration(ArgType) < ConfigurationInterface
    # The type of the argument the converter is applied to.
    getter type : ArgType.class = ArgType
  end

  # This is defined here so that the manual abstract def checks can "see" the `Configuration` type.
  struct Configuration(ArgType) < ArgAwareConfiguration(ArgType); end

  # Only define the default configuration method if the converter does not define a customer one.
  # Because the inherited hook is invoked on the same line as the inheritence happens, e.g. `< ART::ParamConverterInterface`,
  # the `configuration` macro hasn't been expanded yet making it seem like it wasn't defined.
  #
  # Solve this by defining the logic in a `finished` hook to delay execution until all types have been parsed,
  # and only define the type if it does not already exist.
  macro inherited
    macro finished
      {% verbatim do %}
        {% unless @type.has_constant? "Configuration" %}
          # The default `ART::ParamConverterInterface::ConfigurationInterface` object to use
          # if one was not defined via the `ART::ParamConverterInterface.configuration` macro.
          struct Configuration(ArgType) < ArgAwareConfiguration(ArgType); end
        {% end %}
      {% end %}
    end
  end

  # Applies the conversion logic based on the provided *request* and *configuration*.
  #
  # Most commonly this involves setting/overriding a value stored in the request's `ART::Request#attributes`.
  def apply(request : ART::Request, configuration : Configuration) : Nil
    {% if @type < ART::ParamConverterInterface %}
      # Manually check this in order to allow a global overload
      {% @type.raise "abstract `def Athena::Routing::ParamConverterInterface#apply(request : ART::Request, configuration : Configuration)` must be implemented by '#{@type}'." %}
    {% end %}
  end

  # :nodoc:
  def apply(request : ART::Request, configuration) : Nil; end

  # Helper macro for defining an `ART::ParamConverterInterface::ConfigurationInterface`; similar to the `record` macro.
  # Accepts a variable amount of variable names, types, and optionally default values.
  #
  # See the [Additional Configuration][Athena::Routing::ParamConverterInterface--additional-configuration] example of `ART::ParamConverterInterface` for more information.
  macro configuration(*args, type_vars = nil)
    {% begin %}
      # For `{{@type.name}}`.
      {% if type_vars %}\
        struct Configuration(ArgType, {{type_vars.is_a?(Path) ? type_vars.id : type_vars.splat}}) < ArgAwareConfiguration(ArgType)
      {% else %}
        struct Configuration(ArgType) < ArgAwareConfiguration(ArgType)
      {% end %}
        {% for arg in args %}
          getter {{arg}}
        {% end %}

        def initialize(
          name : String,
          converter : ART::ParamConverterInterface.class,
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
