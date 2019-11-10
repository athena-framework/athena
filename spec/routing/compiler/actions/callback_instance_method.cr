require "../../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def teapot_callback(context : HTTP::Server::Context) : Nil
    context.response.status = HTTP::Status::IM_A_TEAPOT
  end
end

Athena::Routing.run
