require "../routing_spec_helper"

struct CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  def action
    123
  end
end

ART.run
