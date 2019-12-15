require "../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/:id")]
  def action(id) : Int32
    123
  end
end

ART.run
