class Athena::Mercure::Hub::Registry
  getter hubs : Hash(String, AMC::Hub::Interface)

  def initialize(
    @default_hub : AMC::Hub::Interface,
    @hubs : Hash(String, AMC::Hub::Interface) = {} of String => AMC::Hub::Interface
  ); end

  def hub(name : String? = nil) : AMC::Hub::Interface
    return @default_hub if name.nil?

    raise AMC::Exception::InvalidArgument.new "No hub named '#{name}' is available." unless @hubs.has_key? name

    @hubs[name]
  end
end
