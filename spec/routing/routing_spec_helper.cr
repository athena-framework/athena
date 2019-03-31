require "spec"
require "http/client"
require "../../src/routing"
require "./controllers/*"

CLIENT = HTTP::Client.new "localhost", 8888

DEFAULT_CONFIG = "athena.yml"
CORS_CONFIG    = "spec/routing/athena.yml"

def do_with_config(path : String = DEFAULT_CONFIG, &block) : Nil
  begin
    spawn do
      Athena::Routing.run(8888, config_path: path)
    end
    Fiber.yield
    yield
  ensure
    Athena::Routing.stop
  end
end

puts
puts
puts "Running Routing Specs"
puts
