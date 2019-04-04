require "../cli"

struct GenerateConfigFileCommand < Athena::Cli::Command
  self.command_name = "athena:generate:config_file"
  self.description = "Generates the default config file for Athena"

  def self.execute(force : Bool? = false, path : String? = "./athena.yml") : Nil
    # Create the `athena.yml` config file on install if it does not exist.
    pp __DIR__
    if !File.exists?(path) || force
      File.open path, "w" do |file|
        file.print "# Config file for Athena.\n"
        file.print Athena::Config::Config.new.to_yaml
      end
    end
  end
end
