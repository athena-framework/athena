# The commands resolved for the current invocation, from the root to the leaf, together with the input bound at each level.
# Exposed via `ACON::Application#command_chain` while a command is running.
#
# ```
# protected def execute(input : ACON::Input::Interface, output : ACON::Output::Interface) : ACON::Command::Status
#   # ./console docker --context=prod compose up
#   context = self.application.command_chain.try(&.input("docker")).try &.option("context") # => "prod"
#
#   ACON::Command::Status::SUCCESS
# end
# ```
#
# Implicit tree levels have no registered command and do not appear, except when the invocation ends on one: the running command is always the last level.
# See [Sub-commands][Athena::Console::Command--sub-commands] for more information.
class Athena::Console::CommandChain
  @levels : Array({ACON::Command, ACON::Input::Interface})

  def initialize(@levels : Array({ACON::Command, ACON::Input::Interface})); end

  # Returns the command of each level, from the root to the leaf.
  def commands : Array(ACON::Command)
    @levels.map &.[0]
  end

  # Returns the input bound at each level, from the root to the leaf.
  def inputs : Array(ACON::Input::Interface)
    @levels.map &.[1]
  end

  # Returns the input bound at the level of the command with the provided *name*, or `nil` if there is no such level.
  #
  # The input of an ancestor level holds the options bound at that level; the running command has the input it was given, arguments included.
  def input(name : String) : ACON::Input::Interface?
    @levels.reverse_each do |(command, input)|
      return input if name == command.name
    end
  end

  # Returns the input bound at the deepest level whose command is an instance of the provided *type*, or `nil` if there is no such level.
  def input(type : T.class) : ACON::Input::Interface? forall T
    @levels.reverse_each do |(command, input)|
      return input if command.is_a? T
    end
  end

  # Returns the command of the level with the provided *name*, or `nil` if there is no such level.
  def command(name : String) : ACON::Command?
    @levels.reverse_each do |(command, _)|
      return command if name == command.name
    end
  end

  # Returns the command of the deepest level that is an instance of the provided *type*, or `nil` if there is no such level.
  def command(type : T.class) : T? forall T
    @levels.reverse_each do |(command, _)|
      return command if command.is_a? T
    end
  end
end
