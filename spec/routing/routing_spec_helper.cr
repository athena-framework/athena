require "../spec_helper_methods"
require "http/client"
require "file_utils"
require "../../src/routing"
require "./controllers/*"

CLIENT         = HTTP::Client.new "localhost", 8888
CORS_CONFIG    = "spec/routing/athena.yml"
DEFAULT_CONFIG = "athena.yml"

Spec.before_each { ENV["ATHENA_ENV"] = "test" }

# Spawns a server with the given confg file path, runs the specs in the describe block, then stops the server.
def do_with_config(path : String = DEFAULT_CONFIG) : Nil
  around_all do |example|
    ENV["ATHENA_ENV"] = "test"
    ENV["ATHENA_CONFIG_PATH"] = path
    spawn { Athena::Routing.run(8888) }
    sleep 0.5
    example.run
  ensure
    CLIENT.close # Close the client so each spec file gets its own connection.
    Athena::Routing.stop
  end
end

puts
puts
puts "Running Routing Specs"
puts
