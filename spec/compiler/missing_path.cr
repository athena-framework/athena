require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ARTA::Get]
  def action : Int32
    123
  end
end

ART.run
