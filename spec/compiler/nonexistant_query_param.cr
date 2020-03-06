require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  @[ART::QueryParam("foo")]
  def action(active : Bool) : Bool
    active
  end
end

ART.run
