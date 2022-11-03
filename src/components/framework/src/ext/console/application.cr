@[ADI::Register(public: true, name: "athena_console_application")]
# Entrypoint for the `Athena::Console` integration.
# This service should be fetched via `ADI.container` within your console CLI file.
#
# Checkout the [external documentation](/components/console/) for more information.
class Athena::Framework::Console::Application < ACON::Application
  def initialize(
    command_loader : ACON::Loader::Interface? = nil,
    event_dipatcher : AED::EventDispatcherInterface? = nil,
    eager_commands : Enumerable(ACON::Command)? = nil
  )
    super "Athena", SemanticVersion.parse ATH::VERSION

    self.command_loader = command_loader
    # TODO: set event dispatcher when that's implemented in the console component.

    eager_commands.try &.each do |cmd|
      self.add cmd
    end
  end
end
