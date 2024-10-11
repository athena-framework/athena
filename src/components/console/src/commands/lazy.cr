# :nodoc:
class Athena::Console::Commands::Lazy < Athena::Console::Command
  @command : Proc(ACON::Command) | ACON::Command
  @enabled : Bool

  delegate :run,
    :merge_application_definition,
    :definition,
    :native_definition,
    :argument,
    :option,
    :process_title,
    :help,
    :processed_help,
    :synopsis,
    :usage,
    :usages,
    :helper,
    to: self.command

  def initialize(
    name : String,
    aliases : Enumerable(String),
    description : String,
    hidden : Bool,
    @command : Proc(ACON::Command),
    @enabled : Bool = true,
  )
    self
      .name(name)
      .aliases(aliases)
      .hidden(hidden)
      .description(description)
  end

  # :inherit:
  def application=(application : ACON::Application?) : Nil
    if (cmd = @command).is_a? ACON::Command
      cmd.application = application
    end

    super
  end

  # :inherit:
  def helper_set=(helper_set : ACON::Helper::HelperSet) : Nil
    if (cmd = @command).is_a? ACON::Command
      cmd.helper_set = helper_set
    end

    super
  end

  # :inherit:
  def enabled? : Bool
    @enabled || self.command.enabled?
  end

  protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
    raise NotImplementedError.new "Use #run instead."
  end

  def command : ACON::Command
    if (cmd = @command).is_a? ACON::Command
      return cmd
    end

    command = @command = cmd.call
    command.application = self.application?

    if hs = self.helper_set
      command.helper_set = hs
    end

    command
      .name(self.name)
      .aliases(self.aliases)
      .hidden(self.hidden?)
      .description(self.description)

    command.definition

    command
  end

  def complete(input : ACON::Completion::Input, suggestions : ACON::Completion::Suggestions) : Nil
    self.command.complete input, suggestions
  end
end
