require "../spec_helper"

@[ARTA::Prefix]
class CompileController < Athena::Routing::Controller
  @[ARTA::Get(path: "/")]
  def action : Int32
    123
  end
end

ART.run
