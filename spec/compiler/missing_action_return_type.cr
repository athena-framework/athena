require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  def action
    123
  end
end

ART.run
