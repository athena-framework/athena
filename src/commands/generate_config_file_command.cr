require "../cli"

# Commands that come with the `athena` executable for Athena specific tasks.
module Athena::Cli::Commands
  # Generates the Athena config file:
  # * force : Bool - Whether to override the existing config file.
  # * path : String - A path that the config file should be generated at.
  struct GenerateConfigFileCommand < Athena::Cli::Command
    self.name = "athena:generate:config_file"
    self.description = "Generates the default config file for Athena"

    def self.execute(force : Bool = false, path : String = "./athena.yml") : Nil
      if !File.exists?(path) || force
        File.open path, "w" do |file|
          file.print "# Config file for Athena.\n"
          file.print Athena::Config::Config.new.to_yaml
        end
      end
    end
  end
end
