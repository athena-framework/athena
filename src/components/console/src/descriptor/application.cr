abstract class Athena::Console::Descriptor; end

# :nodoc:
record Athena::Console::Descriptor::Application, application : ACON::Application, namespace : String? = nil, show_hidden : Bool = false do
  GLOBAL_NAMESPACE = "_global"

  @commands : Hash(String, ACON::Command)? = nil
  @namespaces : Hash(String, NamedTuple(id: String, commands: Array(String)))? = nil
  @aliases : Hash(String, ACON::Command)? = nil

  def commands : Hash(String, ACON::Command)
    if @commands.nil?
      self.inspect_application
    end

    @commands.not_nil!
  end

  def command(name : String) : ACON::Command
    if !@commands.not_nil!.has_key?(name) && !@aliases.not_nil!.has_key?(name)
      raise ACON::Exceptions::CommandNotFound.new "Command '#{name}' does not exist."
    end

    @commands.not_nil![name]? || @aliases.not_nil![name]
  end

  def namespaces : Hash(String, NamedTuple(id: String, commands: Array(String)))
    if @namespaces.nil?
      self.inspect_application
    end

    @namespaces.not_nil!
  end

  private def inspect_application : Nil
    commands = Hash(String, ACON::Command).new
    namespaces = Hash(String, NamedTuple(id: String, commands: Array(String))).new
    aliases = Hash(String, ACON::Command).new

    all_commands = @application.commands((namespace = @namespace) ? @application.find_namespace(namespace) : nil)

    self.sort_commands(all_commands).each do |namespace, command_hash|
      names = Array(String).new

      command_hash.each do |name, command|
        next if command.name.nil? || (!@show_hidden && command.hidden?)

        if name == command.name
          commands[name] = command
        else
          aliases[name] = command
        end

        names << name
      end

      namespaces[namespace] = {id: namespace, commands: names}
    end

    @commands = commands
    @namespaces = namespaces
    @aliases = aliases
  end

  private def sort_commands(commands : Hash(String, ACON::Command)) : Hash(String, Hash(String, ACON::Command))
    namespaced_commands = Hash(String, Hash(String, ACON::Command)).new
    global_commands = Hash(String, ACON::Command).new
    sorted_commands = Hash(String, Hash(String, ACON::Command)).new

    commands.each do |name, command|
      key = @application.extract_namespace name, 1
      if key.in? "", GLOBAL_NAMESPACE
        global_commands[name] = command
      else
        (namespaced_commands[key] ||= Hash(String, ACON::Command).new)[name] = command
      end
    end

    unless global_commands.empty?
      sorted_commands[GLOBAL_NAMESPACE] = self.sort_hash global_commands
    end

    unless namespaced_commands.empty?
      namespaced_commands = self.sort_hash namespaced_commands
      namespaced_commands.keys.sort!.each do |key|
        sorted_commands[key] = self.sort_hash namespaced_commands[key]
      end
    end

    sorted_commands
  end

  private def sort_hash(hash : Hash(String, Hash(String, Athena::Console::Command))) : Hash(String, Hash(String, Athena::Console::Command))
    sorted_hash = Hash(String, Hash(String, Athena::Console::Command)).new

    hash.keys.sort!.each do |k|
      sorted_hash[k] = self.sort_hash hash[k]
    end

    sorted_hash
  end

  private def sort_hash(hash : Hash(String, ACON::Command)) : Hash(String, ACON::Command)
    sorted_hash = Hash(String, ACON::Command).new

    hash.keys.sort!.each do |k|
      sorted_hash[k] = hash[k]
    end

    sorted_hash
  end
end
