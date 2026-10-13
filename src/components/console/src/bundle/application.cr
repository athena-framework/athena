class Athena::Console::Application
  # Creates an application with the provided *name* and *version*, that runs the commands registered as services within the provided *container*.
  # Requires the [Console bundle](/Console/Bundle/) to be registered.
  #
  # ```
  # require "athena-dependency_injection"
  # require "athena-console/bundle"
  #
  # ACON::Application.new("My App", "1.0.0", ADI.container).run
  # ```
  def initialize(@name : String, @version : String, container : ADI::ServiceContainer)
    command_loader = container.console_command_loader
    self.command_loader = command_loader

    command_loader.eager_commands.each do |command|
      self.add command
    end
  end
end
