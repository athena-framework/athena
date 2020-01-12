require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/:id")]
  def action : Int32
    123
  end
end

ART.run
