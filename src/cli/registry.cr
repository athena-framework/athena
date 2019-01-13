module Athena::Cli
  # Stores the available commands.
  struct Registry
    macro finished
      # Array of available commands.  Auto registered at compile time.
      class_getter commands : Array(Athena::Cli::Command.class) = {{Athena::Cli::Command.subclasses}}{% if Athena::Cli::Command.subclasses.size > 0 %} of Athena::Cli::Command.class {% end %}
    end

    # Displays the available commands.
    def self.to_s : String
      String.build do |str|
        str.puts "Registered commands:"
        @@commands.each do |command|
          str.puts "\t#{command.command_name} - #{command.description}"
        end
      end
    end

    # Returns the command with the given name.
    #
    # Raises if no command has that name.
    def self.find(name : String) : Athena::Cli::Command.class
      commandClass = @@commands.find { |c| c.command_name == name }
      raise "No command with the name '#{name}' has been registered" if commandClass.nil?
      commandClass
    end
  end
end
