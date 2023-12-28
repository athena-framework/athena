# :nodoc:
class Athena::Framework::Console::ContainerCommandLoader
  include Athena::Console::Loader::Interface

  @command_map : Hash(String, ACON::Command.class)

  def initialize(
    @command_map : Hash(String, ACON::Command.class),
    @loader : ADI::Console::ContainerCommandLoaderLocator
  ); end

  # :inherit:
  def get(name : String) : ACON::Command
    if !self.has? name
      raise ACON::Exceptions::CommandNotFound.new "Command '#{name}' does not exist."
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
