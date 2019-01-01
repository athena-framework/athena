require "http/server"
require "amber_router"
require "json"
require "CrSerializer"

require "./route_handler"
require "./converters"
require "./types"

macro halt(context, status_code = 200, response = "")
  {{context}}.response.status_code = {{status_code}}
  {{context}}.response.print {{response}}
  {{context}}.response.close
end

module Athena
  # :nodoc:
  module HTTP::Handler
    def call_next(context : HTTP::Server::Context)
      if next_handler = @next
        next_handler.call(context)
      end
    end
  end

  annotation Get; end
  annotation Post; end
  annotation Put; end
  annotation ParamConverter; end
  annotation Trigger; end
  annotation View; end

  class NotFoundException < Exception
    def to_json : String
      {
        code:    404,
        message: @message,
      }.to_json
    end
  end

  enum Listener
    # Executes after the route's handler has been executed
    ON_RESPONSE

    # Executes before the rotue's handler has been executed
    ON_REQUEST
  end

  abstract class ClassController; end

  abstract struct StructController; end

  abstract struct Action; end

  abstract struct Callback; end

  record RouteAction(A) < Action, action : A, path : String, callbacks : Callbacks, method : String, groups : Array(String), requirements = {} of String => Regex
  record Callbacks, on_response : Array(Callback), on_request : Array(Callback)
  record CallbackEvent(E) < Callback, event : E, only_actions : Array(String), exclude_actions : Array(String)

  def self.run(port : Int32 = 8888, binding : String = "0.0.0.0", ssl : OpenSSL::SSL::Context::Server? | Bool? = nil, handlers : Array(HTTP::Handler) = [Athena::RouteHandler.new])
    server : HTTP::Server = HTTP::Server.new handlers
    puts "Athena is leading the way on #{binding}:#{port}"

    unless server.each_address { |_| break true }
      {% if flag?(:without_openssl) %}
        server.bind_tcp(binding, port)
      {% else %}
        if ssl
          server.bind_tls(binding, port, ssl)
        else
          server.bind_tcp(binding, port)
        end
      {% end %}
    end

    server.listen
  end
end
