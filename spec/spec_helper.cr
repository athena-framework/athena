require "spec"
require "http/client"
require "../src/athena"
require "./controllers/*"

CLIENT = HTTP::Client.new "localhost", 8888

spawn Athena.run

sleep 3
