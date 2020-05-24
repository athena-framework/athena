require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/:id")]
  def action(active : Bool) : Bool
    active
  end
end

ART.run
