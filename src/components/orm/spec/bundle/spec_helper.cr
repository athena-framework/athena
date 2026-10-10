require "../spec_helper"
require "../../src/bundle"

# A `MockConnection` from a connection pool, counting how many times connections are returned to it.
class PooledMockConnection < MockConnection
  class_getter released = 0

  def release
    @@released += 1

    super
  end
end

# Connects to `mock://` URLs.
class MockDriver < DB::Driver
  class ConnectionBuilder < DB::ConnectionBuilder
    def initialize(@options : DB::Connection::Options); end

    def build : DB::Connection
      PooledMockConnection.new @options
    end
  end

  def connection_builder(uri : URI) : DB::ConnectionBuilder
    ConnectionBuilder.new self.connection_options(HTTP::Params.parse(uri.query || ""))
  end
end

DB.register_driver "mock", MockDriver

ADI.configure({
  orm: {
    url: "mock://",
  },
})
