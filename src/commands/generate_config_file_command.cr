require "../cli"

# Commands that come with the `athena` executable for Athena specific tasks.
module Athena::Commands
  # Generates the Athena config file.
  # ## Usage
  # `./bin/athena -c athena:generate:config_file --path /path/to/destination --override true`
  # ## Arguments
  # * override : Bool - Whether to override the existing config file.
  # * path : String - The path that the config file should be generated at.
  struct GenerateConfigFileCommand < Athena::Cli::Command
    self.name = "athena:generate:config_file"
    self.description = "Generates the default config file for Athena"

    def self.execute(override : Bool = false, path : String = "athena.yml") : Nil
      if !File.exists?(path) || override
        File.open path, "w" do |file|
          file.puts "# Config file for Athena."
          file.puts Athena::Config::Environments.new.to_yaml
        end
      end
    end
  end
end
