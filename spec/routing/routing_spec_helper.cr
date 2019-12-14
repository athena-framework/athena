require "../spec_helper_methods"
require "../../src/routing"

puts
puts
puts "Running Routing Specs"
puts

def create(*, request : HTTP::Request = create_request, route : ART::Action = create_route) : HTTP::Server::Context
  request.route = route
  HTTP::Server::Context.new request, HTTP::Server::Response.new IO::Memory.new
end

macro create_route(**named_args)
  ART::Route({{(type_vars = named_args[:type_vars]) ? type_vars.splat : "Proc(Int32), Int32".id}}).new(
    controller: ART::Controller,
    argument_names: {{named_args[:argument_names] || "[] of String".id}},
    action: {{named_args[:action] || "Proc(Int32).new { 1 }".id}},
    parameters: {{named_args[:parameters] || "[]".id}} of ART::Parameters::Param
  )
end

def create_request(method : String = "GET", path : String = "path") : HTTP::Request
  HTTP::Request.new method, path
end
