require "../../../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[Athena::Routing::Callback(event: CallbackEvents::OnResponse)]
  def teapot_callback(context : HTTP::Server::Context) : Nil
    context.response.status_code = 412
  end
end

Athena::Routing.run
