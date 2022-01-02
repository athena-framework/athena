require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ATHA::QueryParam("foo")]
  def action(active : Bool) : Bool
    active
  end
end

ATH.run
