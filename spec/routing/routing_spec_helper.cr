require "../spec_helper_methods"
require "../../src/routing"

require "./controllers/*"

puts
puts
puts "Running Routing Specs"
puts

CLIENT = HTTP::Client.new "localhost", 3000

def run_server : Nil
  around_all do |example|
    ENV["ATHENA_ENV"] = "test"
    spawn { ART.run }
    sleep 0.5
    example.run
  ensure
    Athena::Routing.stop
  end

  before_each do
    CLIENT.close # Close the client so each spec file gets its own connection.
  end
end
