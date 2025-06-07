@[ADI::Register(public: true, name: "athena_console_application")]
# Entrypoint for the `Athena::Console` integration.
#
# ```
# # Require your code
# require "./main"
#
# # Run the application
# ATH.run_console
# ```
#
# Checkout the [Getting Started](/getting_started/commands) docs for more information.
class Athena::Framework::Console::Application < ACON::Application
  protected def initialize(
    command_loader : ACON::Loader::Interface? = nil,
    event_dispatcher : ACTR::EventDispatcher::Interface? = nil,
    eager_commands : Enumerable(ACON::Command)? = nil,
  )
    super "Athena", ATH::VERSION

    self.command_loader = command_loader
    # TODO: set event dispatcher when that's implemented in the console component.

    eager_commands.try &.each do |cmd|
      self.add cmd
    end
  end
end
