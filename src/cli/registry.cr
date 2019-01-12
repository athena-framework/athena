module Athena::Cli
  # Stores the commands avalaible.
  class Registry
    macro finished
      class_getter commands : Array(Athena::Cli::Command.class) = {{Athena::Cli::Command.subclasses}}{% if Athena::Cli::Command.subclasses.size > 0 %} of Athena::Cli::Command.class {% end %}
    end

    # Displays the avalaible commands.
    def self.to_s : String
      String.build do |str|
        str.puts "Registered commands:"
        @@commands.each do |command|
          str.puts "\t#{command.command_name} - #{command.description}"
        end
      end
    end
  end
end
