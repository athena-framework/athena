require "../routing_spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get]
  def action : Int32
    123
  end
end

ART.run
