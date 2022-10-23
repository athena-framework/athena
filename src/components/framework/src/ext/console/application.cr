@[ADI::Register(public: true, name: "athena_console_application")]
class Athena::Framework::Console::Application < ACON::Application
  @commands_registered : Bool = false

  def initialize(
    command_loader : ACON::Loader::Interface? = nil,
    event_dipatcher : AED::EventDispatcherInterface? = nil
  )
    super "Athena", SemanticVersion.parse ATH::VERSION

    self.command_loader = command_loader
    # TODO: set event dispatcher when that's implemented in the console component.
  end

  # :inherit:
  def add(command : ACON::Command) : ACON::Command?
    self.register_commands

    super
  end

  # :inherit:
  def find(name : String) : ACON::Command
    self.register_commands

    super
  end

  # :inherit:
  def get(name : String) : ACON::Command
    self.register_commands

    super
  end

  # :inherit:
  def commands(namespace : String? = nil) : Hash(String, ACON::Command)
    self.register_commands

    super
  end

  # :inherit:
  protected def do_run(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    self.register_commands

    # TODO: Something about errors?

    super
  end

  # :inherit:
  protected def do_run_command(command : ACON::Command, input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    # TODO: Something about errors?

    super
  end

  private def register_commands : Nil
    return if @commands_registered

    @commands_registered = true

    # TOOD: Register non lazy commands
  end
end
