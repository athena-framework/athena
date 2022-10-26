@[ADI::Register(public: true, name: "athena_console_application")]
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
