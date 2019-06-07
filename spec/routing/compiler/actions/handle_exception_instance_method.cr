require "../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  def handle_exception(exception : Exception, ctx : HTTP::Server::Context)
    super
  end
end

Athena::Routing.run
