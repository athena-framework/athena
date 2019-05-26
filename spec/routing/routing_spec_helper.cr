require "../spec_helper_methods"
require "http/client"
require "../../src/routing"
require "./controllers/*"

DEFAULT_CONFIG = "athena.yml"
CORS_CONFIG    = "spec/routing/athena.yml"

# Spawns a server with the given confg file path, runs the block, then stops the server.
def do_with_config(path : String = DEFAULT_CONFIG, &block : HTTP::Client -> Nil) : Nil
  client = HTTP::Client.new "localhost", 8888
  ENV["ATHENA_ENV"] = "test"
  spawn { Athena::Routing.run(8888, config_path: path) }
  sleep 0.5
  yield client
ensure
  Athena::Routing.stop
end

puts
puts
puts "Running Routing Specs"
puts
