require "./config"

# This file gets executed on install to initialize Athena.
# Currently just creating the `athena.yml` config file on install if it does not exist.
unless File.exists? "../../athena.yml"
  File.open "../../athena.yml", "w" do |file|
    file.print "# Config file for Athena.\n"
    file.print Athena::Config::Config.new.to_yaml
  end
end
