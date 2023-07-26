# Displays information for a given command.
@[Athena::Console::Annotations::AsCommand("help", description: "Display help for a command")]
class Athena::Console::Commands::Help < Athena::Console::Command
  # :nodoc:
  setter command : ACON::Command? = nil

  protected def configure : Nil
    self.ignore_validation_errors

    self
      .name("help")
      .argument("command_name", description: "The command name", default: "help") { ACON::Descriptor::Application.new(self.application).commands.keys }
      .option("format", value_mode: :required, description: "The output format (txt)", default: "txt") { ACON::Helper::Descriptor.new.formats }
      .option("raw", value_mode: :none, description: "To output raw command help")
      .help(
        <<-HELP
        The <info>%command.name%</info> command displays help for a given command:

          <info>%command.full_name% list</info>

        To display the list of available commands, please use the <info>list</info> command.
        HELP
      )
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    if @command.nil?
      @command = self.application.find input.argument("command_name", String)
    end

    ACON::Helper::Descriptor.new.describe(
      output,
      @command.not_nil!,
      ACON::Descriptor::Context.new(
        format: input.option("format", String),
        raw_text: input.option("raw", Bool),
      )
    )

    @command = nil

    ACON::Command::Status::SUCCESS
  end
end
