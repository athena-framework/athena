require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  def action
    123
  end
end

ART.run
