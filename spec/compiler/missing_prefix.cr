require "../spec_helper"

@[ART::Prefix]
class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  def action : Int32
    123
  end
end

ART.run
