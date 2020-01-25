require "spec"
require "../src/athena"
require "./controllers/*"

Spec.before_suite do
  ENV[Athena::ENV_NAME] = "test"
end

CLIENT = HTTP::Client.new "localhost", 3000

class TestController < ART::Controller
  get "test" do
    "TEST"
  end
end

def new_context(*, request : HTTP::Request = new_request, response : HTTP::Server::Response = new_response) : HTTP::Server::Context
  request.route = ART::Route(TestController, Proc(Proc(String)), String).new(
    ->{ __temp_1502 = TestController.new; ->__temp_1502.get_test }
  )

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

# Asserts compile time errors given a *path* to a program and a *message*.
def assert_error(path : String, message : String) : Nil
  buffer = IO::Memory.new
  result = Process.run("crystal", ["run", "--no-color", "--no-codegen", "spec/" + path], error: buffer)
  fail buffer.to_s if result.success?
  buffer.to_s.should contain message
  buffer.close
end

# Runs the the binary with the given *name* and *args*.
def run_binary(name : String = "bin/athena", args : Array(String) = [] of String, &block : String -> Nil)
  buffer = IO::Memory.new
  Process.run(name, args, error: buffer, output: buffer)
  yield buffer.to_s
  buffer.close
end

# Test implementation of `AED::EventDispatcherInterface` that keeps track of the events that were dispatched.
class TracableEventDispatcher < AED::EventDispatcher
  getter emitted_events : Array(AED::Event.class) = [] of AED::Event.class

  def self.new
    new [] of AED::EventListenerInterface
  end

  def dispatch(event : AED::Event) : Nil
    @emitted_events << event.class

    super
  end
end
