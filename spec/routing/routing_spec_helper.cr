require "spec"
require "http/client"
require "../../src/routing"
require "./controllers/*"

DEFAULT_CONFIG = "athena.yml"
CORS_CONFIG    = "spec/routing/athena.yml"

# Spawns a server with the given confg file path, runs the block, then stops the server
def do_with_config(path : String = DEFAULT_CONFIG, &block : HTTP::Client -> Nil) : Nil
  client = HTTP::Client.new "localhost", 8888
  spawn { Athena::Routing.run(8888, config_path: path) }
  sleep 0.5
  yield client
ensure
  Athena::Routing.stop
end

# Asserts compile time errors given a path to a program and a message.
def assert_error(path : String, message : String) : Nil
  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "spec/routing/compiler/" + path], error: buffer)
  result.success?.should be_false
  buffer.to_s.should contain message
  buffer.close
end

puts
puts
puts "Running Routing Specs"
puts
