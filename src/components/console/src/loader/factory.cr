require "./interface"

# A default implementation of `ACON::Loader::Interface` that accepts a `Hash(String, Proc(ACON::Command))`.
#
# A factory could then be set on the `ACON::Application`:
#
# ```
# application = MyCustomApplication.new "My CLI"
#
# application.command_loader = Athena::Console::Loader::Factory.new({
#   "command1"        => Proc(ACON::Command).new { Command1.new },
#   "app:create-user" => Proc(ACON::Command).new { CreateUserCommand.new },
# })
#
# application.run
# ```
struct Athena::Console::Loader::Factory
  include Athena::Console::Loader::Interface

  @factories : Hash(String, Proc(ACON::Command))

  def initialize(@factories : Hash(String, Proc(ACON::Command))); end

  # :inherit:
  def get(name : String) : ACON::Command
    if factory = @factories[name]?
      factory.call
    else
      raise ACON::Exceptions::CommandNotFound.new "Command '#{name}' does not exist."
    end
  end

  # :inherit:
  def has?(name : String) : Bool
    @factories.has_key? name
  end

  # :inherit:
  def names : Array(String)
    @factories.keys
  end
end
