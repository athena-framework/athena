# Provides a set of services from the container by their ID, only instantiating a service once it is requested.
#
# Useful when a service only needs some of many services at runtime, e.g. based on the request, so that the others are not instantiated.
#
# A service locator is injected into a parameter typed as `ADI::ServiceLocator(T)`, where `T` is a type every provided service is compatible with.
# Its value is a hash of the services it provides, keyed by the ID they are requested with:
#
# ```
# module FormatterInterface
#   abstract def format(data : String) : String
# end
#
# @[ADI::Register]
# class JSONFormatter
#   include FormatterInterface
#
#   def format(data : String) : String
#     %({"data": "#{data}"})
#   end
# end
#
# @[ADI::Register]
# class XMLFormatter
#   include FormatterInterface
#
#   def format(data : String) : String
#     "<data>#{data}</data>"
#   end
# end
#
# @[ADI::Register(public: true, _formatters: {"json" => "@json_formatter", "xml" => "@xml_formatter"})]
# class Renderer
#   def initialize(@formatters : ADI::ServiceLocator(FormatterInterface)); end
#
#   def render(format : String, data : String) : String
#     # Only the formatter of the requested format is instantiated.
#     @formatters.get(format).format data
#   end
# end
#
# ADI.container.renderer.render "xml", "foo" # => "<data>foo</data>"
# ```
#
# Within a bundle extension, the hash is the `value` of the parameter, e.g. `parameters: {formatters: {value: {"json" => "@json_formatter"}}}`.
class Athena::DependencyInjection::ServiceLocator(T)
  # Creates a locator providing the services returned by the provided *factories*, keyed by their ID.
  def initialize(@factories : Hash(String, Proc(T))); end

  # Returns the service with the provided *id*, instantiating it if it has not been already.
  #
  # Raises a `KeyError` if this locator does not provide a service with that *id*.
  def get(id : String) : T
    factory = @factories.fetch(id) { raise KeyError.new self.not_found_message(id) }

    factory.call
  end

  # Returns the service with the provided *id*, instantiating it if it has not been already, or `nil` if this locator does not provide it.
  def get?(id : String) : T?
    @factories[id]?.try &.call
  end

  # Returns `true` if this locator provides a service with the provided *id*, otherwise `false`.
  def has?(id : String) : Bool
    @factories.has_key? id
  end

  # Returns the IDs of the services this locator provides.
  def provided_services : Array(String)
    @factories.keys
  end

  private def not_found_message(id : String) : String
    String.build do |io|
      io << "Service '" << id << "' not found: the current service locator "

      case @factories.size
      when 0
        io << "is empty."
      when 1
        io << "only knows about the '" << @factories.first_key << "' service."
      else
        *alternatives, last = @factories.keys

        io << "only knows about the '" << alternatives.join("', '") << "' and '" << last << "' services."
      end
    end
  end
end
