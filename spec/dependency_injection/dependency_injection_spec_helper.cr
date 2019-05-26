require "../spec_helper_methods"
require "../../src/di"

CONTAINER = Athena::DI::ServiceContainer.new

Spec.before_each { ENV["ATHENA_ENV"] = "test" }

puts
puts
puts "Running Dependency Injection Specs"
puts
