require "spec"

require "../../src/config/config"

CONFIG_CONFIG = "spec/config/athena.yml"

Spec.before_each { ENV["ATHENA_ENV"] = "test" }

puts
puts
puts "Running Config Specs"
puts
