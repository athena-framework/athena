require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::QueryParam("foo")]
  def action(active : Bool) : Bool
    active
  end
end

ART.run
