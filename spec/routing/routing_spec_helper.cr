require "../spec_helper_methods"
require "http/client"
require "file_utils"
require "../../src/routing"
require "./controllers/*"

DEFAULT_CONFIG = "athena.yml"
CORS_CONFIG    = "spec/routing/athena.yml"

Spec.before_each { ENV["ATHENA_ENV"] = "test" }

# Spawns a server with the given confg file path, runs the block, then stops the server.
def do_with_config(path : String = DEFAULT_CONFIG, &block : HTTP::Client -> Nil) : Nil
  ENV["ATHENA_CONFIG_PATH"] = path
  client = HTTP::Client.new "localhost", 8888
  spawn { Athena::Routing.run(8888) }
  sleep 0.5
  yield client
ensure
  Athena::Routing.stop
end

puts
puts
puts "Running Routing Specs"
puts
