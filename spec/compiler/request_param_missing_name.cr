require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ART::Get(path: "/")]
  @[ART::RequestParam]
  def action(all : Bool) : Int32
    123
  end
end

ART.run
