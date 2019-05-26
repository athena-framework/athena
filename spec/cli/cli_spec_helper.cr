require "../spec_helper_methods"
require "../../src/cli"
require "./commands/*"

Spec.before_each { ENV["ATHENA_ENV"] = "test" }

puts
puts
puts "Running CLI Specs"
puts
