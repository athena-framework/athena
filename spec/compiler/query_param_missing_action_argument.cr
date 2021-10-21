require "../spec_helper"

class CompileController < Athena::Framework::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::QueryParam("foo")]
  def action(active : Bool) : Bool
    active
  end
end

ATH.run
