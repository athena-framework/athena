require "../spec_helper_methods"
require "../../src/routing"

require "./controllers/*"

puts
puts
puts "Running Routing Specs"
puts

CLIENT = HTTP::Client.new "localhost", 3000

def new_context(*, request : HTTP::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  HTTP::Server::Context.new request, response
end

def new_request(*, path : String = "test", method : String = "GET") : HTTP::Request
  HTTP::Request.new method, path
end

def new_response(*, io : IO = IO::Memory.new) : HTTP::Server::Response
  HTTP::Server::Response.new io
end

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
