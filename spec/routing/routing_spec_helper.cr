require "spec"
require "http/client"
require "../../src/routing"
require "./controllers/*"

CLIENT = HTTP::Client.new "localhost", 8888

puts
puts
puts "Running Routing Specs"
puts

Athena::Routing.static_file_handler = HTTP::StaticFileHandler.new("spec/public", directory_listing: false)

spawn Athena::Routing.run

sleep 1.5
