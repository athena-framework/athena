require "../spec_helper"

class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  @[ARTA::RequestParam]
  def action(all : Bool) : Int32
    123
  end
end

ART.run
