# The [AMC::Hub::Registry][] can be used to store multiple [AMC::Hub][] instances, accessing them by unique names.
#
# ```
# foo_hub = hub = AMC::Hub.new ENV["FOO_HUB_MERCURE_URL"], foo_token_provider, foo_token_factory
# bar_hub = hub = AMC::Hub.new ENV["BAR_HUB_MERCURE_URL"], bar_token_provider, bar_token_factory
#
# registry = AMC::Hub::Registry.new(
#   foo_hub,
#   {
#     "foo" => foo_hub,
#     "bar" => bar_hub,
#   } of String => AMC::Hub::Interface
# )
#
# registry.hub       # => (default foo_hub)
# registry.hub "bar" # => (bar_hub)
# ```
class Athena::Mercure::Hub::Registry
  # Returns the mapping of hub names to their related instance.
  getter hubs : Hash(String, AMC::Hub::Interface)

  def initialize(
    @default_hub : AMC::Hub::Interface,
    @hubs : Hash(String, AMC::Hub::Interface) = {} of String => AMC::Hub::Interface,
  ); end

  # Returns the hub with the provided *name*, or the default one if no name was provided.
  def hub(name : String? = nil) : AMC::Hub::Interface
    return @default_hub if name.nil?

    raise AMC::Exception::InvalidArgument.new "No hub named '#{name}' is available." unless @hubs.has_key? name

    @hubs[name]
  end
end
