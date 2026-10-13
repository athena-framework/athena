# :nodoc:
#
# Provides the commands registered as services to `ACON::Application.new(name, version, container)`.
# Commands with an `ACONA::AsCommand` annotation are loaded lazily, while *eager_commands* are added to the application directly.
class Athena::Console::Bundle::ContainerCommandLoader
  include Athena::Console::Loader::Interface

  getter eager_commands : Array(ACON::Command)

  def initialize(
    @command_map : Hash(String, ACON::Command.class),
    @loader : ACON::Bundle::ContainerCommandLoaderLocator,
    @eager_commands : Array(ACON::Command),
  ); end

  # :inherit:
  def get(name : String) : ACON::Command
    if !self.has? name
      raise ACON::Exception::CommandNotFound.new "Command '#{name}' does not exist."
    end

    @loader.get @command_map[name]
  end

  # :inherit:
  def has?(name : String) : Bool
    @command_map.has_key? name
  end

  # :inherit:
  def names : Array(String)
    @command_map.keys
  end
end

# :nodoc:
#
# Defined by `ACON::Bundle::CompilerPasses::RegisterCommands` with a method to get each lazy command from the container.
struct Athena::Console::Bundle::ContainerCommandLoaderLocator; end
